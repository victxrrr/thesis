There are several steps that can be parallelized in the original program structure @hydroflow. First, one may imagine that writing processes such as pictures or gauge snapshots can be done in parallel with the main finite-volume computations. This corresponds to the #text(fill: green, [green]) box in the diagram. Furthermore, the flux and source term computations, as well as the finite-volume update, are mostly independent from one interface or cell to another, so we could distribute the loop iterations over multiple processor cores. These correspond to the #text(fill:blue, [blue]) boxes. Finally, the minimum involved in the time step computation can also be parallelized by dividing the domain into subdomains, computing the local minimum in each subdomain, and then merging the results. This corresponds to the #text(fill:red, [red]) box.

As recalled in the state of the art, several technologies exist to implement these parallelizations. First, we have to choose the paradigm to follow between the shared-memory and distributed-memory approaches. We chose to focus on a thread-based parallelization for several reasons:

- We aim for a parallel version that benefits the largest number of users, while MPI implementations are more suited for use on clusters;

- The flux computation at each interface requires knowledge of the hydraulic variables $bold(U)$ from the left and right cells. Partitioning the cell array would then involve communication overhead to share ghost cell states surrounding boundary interfaces;

- Although distributed memory implementations allow the processing of larger meshes that would not fit into a single computer's RAM, we argue that the current Watlab implementation is still mainly limited by execution time, not memory.

The previous study showed that using threads and mutex-based synchronization to parallelize output writing and OpenMP to parallelize loops was the most efficient and easy-to-deploy way to implement the shared-memory model @Gamba. The original Watlab implementation we received at the beginning of the year still contained a broken version of this approach, so our work was more a rehabilitation than a development from scratch.

Regarding output, there is a small subtlety: writing and computation processes are not fully independent since they rely on the same data, namely the hydraulic variables. If the writing thread outputs concurrently while the finite-volume update is in progress, it leads to race conditions, as written values may vary between runs. To avoid this, careful synchronization is required. For example, computational threads can compute fluxes and source terms while cell data is being output since these intermediate values are not saved, but they must wait for the writing process to finish before altering the hydraulic variables during the finite-volume update. \
To minimize idle times and avoid significant delays for computational threads and minimize idle times, writer threads make a local copy of the data to output using a preallocated buffer, which is faster than I/O operations. On the other hand, synchronization relies on mutexes: when launched, writers lock a mutex to indicate they intend to buffer cell data. Once done, they release the mutex, signaling that the backup copy is ready and proceed to write to files. Meanwhile, after computing fluxes and source terms, the finite-volume threads try to lock the same mutexes and will wait if writers have not yet finished buffering.

Finally, we slightly modified the implementation of the minimum computation. The original approach from @Gamba parallelized the loop over cells using OpenMP, with each thread storing intermediate results in a thread-local variable before merging them to find the global minimum. Since loop iterations are distributed across OpenMP threads, this acts like a domain subdivision, although the cells within each local region may not be contiguous. However, the merging strategy was suboptimal: each thread compared its result with a global variable inside a critical section, making the merging inherently sequential with linear complexity in the number of threads.

This can be improved using a parallel reduction, which resembles a tournament. First, threads form pairs and compare values in parallel, then winners form new pairs and repeat the process until one thread remains. This reduces the global minimum in $log_2(T)$ steps instead of $T$, where $T$ is the number of threads. An illustrative diagram of the reduction strategy is shown in @reduction. While this optimization may have little impact with the small number of cores typical in modern CPUs, it becomes significant for GPU implementations with many more cores. For example, 2560 parallel processes would require only 12 reduction rounds. Furthermore, it allows us to leverage cache memory because threads only need to know their local minimum and the local minimums of the other threads with which they compete.

#import "@preview/fletcher:0.5.3" as fletcher: diagram, node, edge, measure-node-size

#let scale_width(canvas) = {
  context {
    let canvas-size = measure(canvas)
    layout(size => {
      scale(size.width/canvas-size.width * 100%, canvas)
    })
  }
}

#let c = {
  diagram(
	spacing: 8pt,
	cell-size: (8mm, 10mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
  node-fill: luma(94%),
	node-outset: 3pt,
  debug: 0,

  edge((-1, -.75), (15, -.75)),
  edge((-1, -1.5), (15, -1.5)),
  for v in range(0, 9) {
    edge((-1 + v * 2, -.75), (-1+ v * 2, -1.5))
  },

  node((0, 0), [#set text(size:13pt)
  13], name: <13>),
  node((2, 0), [27], name: <27>),
  node((4, 0), [15], name: <15>),
  node((6, 0), [14], name: <14>),
  node((8, 0), [33], name: <33>),
  node((10, 0), [2], name: <2>),
  node((12, 0), [24], name: <24>),
  node((14, 0), [6], name: <6>),

  node((1, 1), [13], name: <1313>),
  node((5, 1), [14], name: <1414>),
  node((9, 1), [2], name: <22>),
  node((13, 1), [6], name: <66>),

  node((3, 2), [13],name:  <131313>),
  node((11,2), [2], name: <222>),

  node((7, 3), [2], name: <2222>),

  edge(<13>, <1313>, "-|>"),
  edge(<27>, <1313>, "-|>"),

  edge(<15>, <1414>, "-|>"),
  edge(<14>, <1414>, "-|>"),

  edge(<33>, <22>, "-|>"),
  edge(<2>, <22>, "-|>"),

  edge(<24>, <66>, "-|>"),
  edge(<6>, <66>, "-|>"),

  edge(<1313>, <131313>, "-|>"),
  edge(<1414>, <131313>, "-|>"),

  edge(<22>, <222>, "-|>"),
  edge(<66>, <222>, "-|>"),

  edge(<222>, <2222>, "-|>"),
  edge(<131313>, <2222>, "-|>")
)
}

#figure(
  scale_width(c), caption: [Minimum reduction]
)<reduction>

Fortunately, OpenMP provides built-in support for parallel reduction via the reduction keyword, abstracting implementation details and simplifying the code, as shown in the following pseudocode:
```cpp
#pragma omp parallel for reduction(min:tmin)
for (int i = 0; i < nCells; i++) {
  if (Cell[i].tmin < tmin) tmin = Cell[i].tmin;
}
```
The updated structure of the final parallel implementation is shown in @hydroflow_parallel.

#let light_blob(pos, label, tint: white, ..args) = node(
	pos, align(center, label),
	fill: tint.lighten(90%),
	stroke: 1pt + tint.lighten(30%),
	corner-radius: 5pt,
	..args,
)

#let blob(pos, label, tint: white, ..args) = node(
	pos, align(center, label),
	fill: tint.lighten(70%),
	stroke: 1pt + tint.darken(20%),
	corner-radius: 5pt,
	..args,
)

#let scale_width2(canvas) = {
  context {
    let canvas-size = measure(canvas)
    layout(size => {
      scale(100%, canvas)
    })
  }
}

#figure(placement: auto, gap: 10pt, scale_width2(diagram(
	spacing: 8pt,
	cell-size: (8mm, 10mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
  debug: 0,

  let pos = 0,
  let dy = 1.25,
  let shadow = .025,
  let output_dx = -.85,
  blob((0, pos - dy), [Initialization], tint: gray, name: <h2d>),
  edge("-|>"),
  blob((0, pos), [Time to output ?], tint: gray, name: <if>),

  let side = pos,
  side += dy,
  blob((output_dx, side), [Has previous \ output finished ?], tint: gray, name: <yes>),
  edge(<yes.south-east>, "-|>", <yes.north-east>, [no],  bend: -125deg, label-pos: .6),
  side += 1.15*dy,
  edge("-|>", label: "yes", label-side: left),
  blob((output_dx, side), [Buffer data], tint: green, name: <save>),
  side += dy,
  edge("-|>"),
  blob((output_dx, side), [Write data], tint: green, name: <write>),

  pos += dy,
  light_blob((2*shadow, pos), [ $ quad$], width: 41mm, tint: blue, name: <last_flux>),
  edge(<if.south>, (<last_flux.north-west>, 85%, <last_flux.north>), "-|>"),
  pos += .15,
  light_blob((shadow, pos), [ $ quad$], width: 41mm, tint: blue),
  pos += .15,
  blob((0, pos), [$bold(F)_j^*$ #h(.5em) *for each* interface ], tint: blue, name: <flux>),

  pos += dy,
  light_blob((2*shadow, pos), [$quad$], width: 32mm, tint: blue, name: <last_source>),
  edge(<flux.south>, (<last_source.north-west>, 80%, <last_source.north>), "-|>"),
  pos += .15,
  light_blob((shadow, pos), [$quad$], width: 32mm, tint: blue),
  pos += .15,
  blob((0, pos), [$bold(S)_i^*$ #h(.5em) *for each* cell], tint: blue, name: <update>),

  pos += dy,
  blob((0, pos), [Has data been buffered ?], tint: gray, name: <buf>),
  edge(<buf.south-east>, "-|>", <buf.north-east>, [no],  bend: -135deg, label-pos: .6),
  pos += dy*1.125,

  light_blob((2*shadow, pos), [$quad$], width: 104.5mm, height: 9mm, tint:blue, name: <last_update>),
  edge(<buf.south>, (<last_update.north-west>, 60%, <last_update.north>), "-|>", label: [yes], label-side: left),
  pos += .15,
  light_blob((shadow, pos), [$quad$], width: 104.5mm, height: 9mm, tint:blue),
  // blob((0, 5.80 + .3), [$bold(U)_i^(n+1) = bold(U)_i^n - (Delta t)/A_i sum bold(F)^*_(i,j) n_(i,j) L_(i,j) + bold(S)_i^* Delta t$ #h(.5em) *for each* cell], 100mm, tint: blue, name: <min>),
  pos += .15,
  blob((0, pos), [$bold(U)_i^(n+1) = bold(U)_i^n - (Delta t \/ abs(cal(C)_i)) sum_(j) bold(T)^(-1)_j bold(F)^*_j  L_j + bold(S)_i^* Delta t$ #h(.5em) *for each* cell], tint: blue, height: 9mm, name: <min>),

  pos += dy*1.2,
  light_blob((0.05, pos), [$quad$], width: 35.5mm, height: 9mm, tint: red, name: <last_min>),
  edge(<min.south>, (<last_min.north-west>, 82.5%, <last_min.north>), "-|>", label: [yes], label-side: left),

  pos += .15,
  light_blob((0.025, pos), [$quad$], width: 35.5mm, height: 9mm, tint: red),
  // blob((0, 7.35 + 2*.15), [ $Delta t = min (Delta x)/(abs(u_i) + c_i)$], 35mm, tint: red, name: <d2h>),
  pos += .15,
  blob((0, pos), [$Delta t = min_i ( (Delta x)/(abs(u) + c) )_i$], height: 9mm, tint: red, name: <red>),

  pos += dy*1.1,
  blob((0, pos), [$t >= t_"end"$ ?], tint: gray, name: <d2h>),
  pos += dy,
  blob((0, pos), [Termination], tint: gray, name: <end>),

  edge(<update>, <buf>, "-|>"),
  edge(<if>, <yes>, "..|>", corner: left, label: "yes", label-pos:.25),

  edge(<d2h>, "r", (rel: (0, -9.25)), "l","--|>", label: "no", label-pos: .175, label-side: right),
  edge(<red>, <d2h>, "-|>", label: [$t = t + sigma Delta t$], label-side: left),

  edge(<d2h>, <end>, "-|>", label: "yes", label-side: left),

  let off = .4,
  edge(<write.south>, (output_dx, 4.5 + off), "-"),
  edge((output_dx, 4.5 + off), (output_dx, 5 + off), "--")
)), caption: [Updated program structure of the parallel implementation]) <hydroflow_parallel>

A subtlety remains in the program structure shown in @hydroflow and @hydroflow_parallel. The sum in @update is not performed while iterating over cells. Instead, each cell is linked to a buffer, reinitialized at each time step, where fluxes computed at each interface accumulate#footnote[Actually, multiplied by constants reflecting coordinate transforms and scaled by interface lengths] during the first step of flux computation. This requires each interface to store references to its left and right cells, unless it lies on the boundary. In the update step, the flux sum is retrieved from the buffer as a constant and combined with source term contributions. A diagram of this interface-based approach appears in @interf_based.

In contrast, a cell-based approach as in @cell_based may feel more intuitive given the mathematical formulation. To support it, each cell must store a list of references to its adjacent interfaces. Though both approaches require the same number of floating point operations, they differ in memory access patterns. As shown in @memory_fluxes, both lead to the same number of memory accesses (i.e., same number of arrows in the figures). However, in the interface-based approach, flux-balancing memory accesses happen earlier since computing fluxes with the HLLC scheme requires hydraulic variables from both sides. These are likely already in cache and thus cheap to access. A reminder on cache mechanisms is given in @memory_section. On the other hand, the cell-based approach involves three uncached and costly memory accesses per cell during the update step. This can only be partially mitigated by reordering so that neighboring interfaces have nearby indices.

#import "@preview/subpar:0.2.2"
#subpar.grid(
  figure(image("../img/edge_based.svg", width: 70%), gap: .75em, caption: [
    Interface-based approach
  ]), <interf_based>,
  figure(image("../img/cell_based.svg", width: 70%), gap: .75em, caption: [
    Cell-based approach
  ]), <cell_based>,
  columns: (1fr, 1fr),
  caption: [Memory accesses of flux balances],
  label: <memory_fluxes>,
  numbering: n => {
    let h1 = counter(heading).get().first()
    numbering("1.1", h1, n)
  }, gap: 1em
)

The main caveat of the interface-based approach is the greater difficulty in parallelizing it. While interfaces are processed in parallel by multiple threads, two threads may attempt to access the same cell at the same time, potentially causing a race condition. To avoid this, cell buffers must be protected with mutexes, ensuring only one thread modifies them at a time. This adds some serialization overhead, but it remains low, as the typically large number of interfaces spread across threads makes simultaneous access to the same cell unlikely.
