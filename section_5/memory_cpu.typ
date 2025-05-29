#import "@preview/subpar:0.2.2"

// #show: subpar.grid(numbering-sub-ref: "R1.a")
//
// #show ref: it => {
//   let el = it.element
//   if el != none and el.has("kind") and el.kind in (image, raw) {
//     // Override references.
//     [Figure #counter(heading).at(el.location()).first()\.#counter(figure.where(kind: el.kind)).at(el.location()).first()]
//   } else {
//     // Other references as usual.
//     it
//   }
// }

=== Roofline analysis


To gain further insights into the bottlenecks in the program and identify what exactly should be optimized, we should first determine whether the program is _compute bound_, meaning the CPU reaches its floating point functional limits, or _memory bound_, meaning the CPU spends most of its cycles waiting on data loads and stores. This is mainly determined by the _data intensity_ of the implemented algorithm, which refers to the ratio of floating point operations to the number of bytes moved. The _Roofline model_ @RL relates data intensity to the number of floating point operations per second by showing the maximum achievable performance on the system, depending on the peak achievable bandwidth and the peak performance of the processor.

If we can empirically measure the data intensity and the floating point throughput, we can place an algorithm on the Roofline. The roof that intersects with the vertical line drawn from that point allows us to determine whether it is compute bound or memory bound. Furthermore, the vertical gap between the algorithm and the roof helps assess whether there is room for improvement or if the program already pushes the hardware to its functional limits.

To do this, we used Intel Advisor, which is able to analyze each function separately. The resulting analysis is shown in @RL_global. Each circle represents a function call, with its size and color proportional to its self execution time. Therefore, large red circles are the most important to optimize according to Amdahl's law. The green circle in the lower left represents the `Domain::Update` function, which roughly corresponds to the full program execution. Its low data intensity indicates that Watlab is essentially a memory bound program. We can zoom into the different child functions to gain further insights, as shown in @RL_zoom.

#subpar.grid(
  figure(image("../img/roofline_global.svg", width: 100%), gap: .75em, caption: [
    Distribution of functions in the Roofline model
  ]), <RL_global>,
  figure(image("../img/roofline_zoom_annotated.svg", width: 100%), gap: .75em, caption: [
    Zoom
  ]), <RL_zoom>,
  columns: 1,
  caption: [Roofline analysis of Hydroflow using Intel Advisor],
  placement: auto,
  numbering: n => numbering("1.1", ..counter(heading.where(level: 1)).get(), n),
  numbering-sub-ref: (..n) => {
    numbering("1.1a", ..counter(heading.where(level: 1)).get(), ..n)
  },
  gap: 1em
)
We see that all functions except `dtMin` lie below the peak bandwidth of the third cache. This suggests that greater use of the first and second cache levels may improve performance.

=== Leveraging caches <section_reordering>

From their inception, CPUs have continually become faster. Memory speeds have also increased, but not at the same pace as CPUs @ss. While a processor can perform several operations per clock cycle, accessing data from main memory can take tens of cycles @Eijkhout. This phenomenon is known as the _memory wall_ @memory_wall.

To alleviate this bottleneck, faster on-chip memory called _cache_ was developed, greatly reducing memory access times. However, cache hardware consumes more power and requires more transistors than main memory, which limits its capacity. Caches are divided into _cache lines_, typically 64 bytes long on modern processors. Each cache line stores a copy of a memory block from main memory.

When the CPU needs to read an address from main memory, it first checks whether the data is already present in the cache. If it is, this is called a _cache hit_. If not, it results in a _cache miss_, and the data must be loaded from main memory into a cache line, possibly evicting another line to make room, before being moved from the cache to the registers.

Although cache behavior is managed by the hardware and not under direct programmer control, writing code with cache usage in mind can significantly improve performance. Specifically, maximizing _temporal_ and _spatial locality_ increases the likelihood of cache hits. Temporal locality refers to the tendency of programs to reuse the same data within short time intervals. Spatial locality characterizes that programs tend to access memory locations that are close to each other @Eijkhout.

To evaluate the number of cache hits and misses during the execution of Watlab, we used Cachegrind, a tool from the Valgrind framework @Valgrind, which simulates cache behavior and provides line-by-line annotations of source code indicating the number of cache read and write misses.

In the original Watlab implementation, intermediate results used in the flux computations at boundary and inner interfaces were stored in member variables, i.e., variables that are part of a class object and accessible by all functions within the class. Cachegrind analysis revealed that these member variables caused numerous cache misses, as they were accessed only once per iteration and stored in main memory. Furthermore, most of these variables were only used inside the flux computation methods.

As a first memory optimization, we converted these into local variables, restricting their scope to the flux computation function whenever possible. This ensured they were stored on the stack or in registers, which are theorically faster to access.

Additionally, other cache misses were related to memory accesses during iterations over cells, for computing source terms, updating hydraulic variables, computing the next time step, or over interfaces for flux computation. These accesses involve simple traversals of arrays of structures (cells and interfaces), and cannot be further optimized. The memory layout of cells, nodes, and interfaces follows the order in the input files generated by the preprocessing Python API.

However, during flux computations at each interface, we must access the left and right cells to retrieve associated water heights for inner interfaces, or only the left cell for boundary interfaces. If the cells are renumbered such that the index difference between left and right cells is minimized, we can benefit from improved spatial locality, as the accessed cells are likely to be closer in memory. \
Fortunately, this is precisely what the reverse Cuthill-McKee algorithm (RCM) can help us to do. It is initially designed to permute a symmetric sparse matrix in order to reduce its bandwidth. In our case, this matrix corresponds to the adjacency matrix derived from the dual graph associated with the mesh. If you consider each cell as a node in a graph connected to neighboring cells, i.e., each inner interface represents an edge, you can easily derive an adjacency matrix. \
To illustrate, we consider a simple square mesh composed of 26 triangular elements  (@square_mesh). The lower triangular part of the original symmetric adjacency matrix is shown in @adj_v1, while the upper triangular part represents the updated matrix after applying the reverse Cuthill-McKee algorithm. The bandwidth of the resulting matrix is much smaller, meaning that left and right cell indices of each interface are now closer in memory. \
However, However, this renumbering strategy alone will not reduce the number of cache misses. This is because, while spatial locality is improved, temporal locality is simultaneously degraded. The colors of each entry in the adjacency matrices represent the corresponding interface indices, ranging from #text(fill: rgb("#03fcff"))[cyan] (low indices) to #text(fill: rgb("#fc03ff"))[pink] (high indices). In the initial lower matrix, we observe a smooth gradient from left to right. This is linked to how GMSH @GMSH, the mesh generator used to produce the mesh files feeding Watlab, numbers the interfaces. A closer look at @square_mesh reveals that it first numbers boundary interfaces in a counterclockwise manner. Then, inner interfaces are ordered by the left cell index and, for interfaces sharing the same left index, by the right cell index. As interfaces are processed in order, this improves temporal locality by increasing the likelihood of accessing common neighboring cells consecutively. \
After reordering the cells, we lose this benefit. The new indices disrupt the original sorting, as shown by the shuffled colors in the updated adjacency matrix of @adj_v1. The solution, however, is quite straightforward. We can simply renumber the interfaces by sorting them based on the new left and right indices, using an algorithm like Quicksort @quicksort (@adj_v2). \
This renumbering strategy was originally proposed by @LACASTA20141 in the context of GPU computing but we realised that it was also relevant for CPU execution, as demonstrated in the above discussion.

#subpar.grid(
  figure(image("../img/no_RCM.svg", width: 81%), gap: .75em, caption: [
    Before reordering
  ]), <square_mesh>,
  figure(image("../img/RCM.svg", width: 81%), gap: .75em, caption: [
    After reordering
  ]), <after_reordering>,
  columns: 1,
  caption: [A simple square mesh with 26 cells and 45 interfaces],
  placement: auto,
  numbering: n => numbering("1.1", ..counter(heading.where(level: 1)).get(), n),
  numbering-sub-ref: (..n) => {
    numbering("1.1a", ..counter(heading.where(level: 1)).get(), ..n)
  },
  gap: 1em
)

#subpar.grid(
  figure(move(image("../img/adj_RCM.svg", width: 77%), dx:6%), gap: .75em, caption: [
    Renumbering cells using the reverse Cuthill-McKee algorithm
  ]), <adj_v1>,
  figure(move(image("../img/adj_RCM_QS.svg", width: 77%), dx: 6%), gap: .75em, caption: [
    Renumbering cells using the reverse Cuthill-McKee algorithm and interfaces using Quicksort
  ]), <adj_v2>,
  columns: 1,
  caption: [Adjacency matrices related to the square mesh],
  placement: auto,
  numbering: n => numbering("1.1", ..counter(heading.where(level: 1)).get(), n),
  numbering-sub-ref: (..n) => {
    numbering("1.1a", ..counter(heading.where(level: 1)).get(), ..n)
  },
  gap: 1em
)


// dire pourquoi j'ai mis le reordering dans python

// tester si cest ap mieux de faire comme GMSH pour numeroter les edges
// i.e. d'abord numeroter les frontieres puis les inners
