There are several steps that can be parallelized in the original program structure @hydroflow. First, one may imagine that writing processes such as pictures or gauge snapshots can be done in parallel with the main finite-volume computations. This corresponds to the #text(fill: green, [green]) box in the diagram. Furthermore, the flux and source term computations, as well as the finite-volume update, are mostly independent from one interface or cell to another, so we could distribute the loop iterations over multiple processor cores. These correspond to the #text(fill:blue, [blue]) boxes. Finally, the minimum involved in the time step computation can also be parallelized by dividing the domain into subdomains, computing the local minimum in each subdomain, and then merging the results. This corresponds to the #text(fill:red, [red]) box.

As recalled in the state of the art, several technologies exist to implement these parallelizations. First, we have to choose the paradigm to follow between the shared-memory and distributed-memory approaches. We chose to focus on a thread-based parallelization for several reasons:

- We aim for a parallel version that benefits the largest number of users, while MPI implementations are more suited for use on clusters;

- The flux computation at each interface requires knowledge of the hydraulic variables $bold(U)$ from the left and right cells. Partitioning the cell array would then involve communication overhead to share ghost cell states surrounding boundary interfaces;

- Although distributed memory implementations allow the processing of larger meshes that wouldn't fit into a single computer's RAM, we argue that the current Watlab implementation is still mainly limited by execution time, not memory.

The previous study showed that using threads to parallelize output writing and OpenMP to parallelize loops was the most efficient and easy-to-deploy way to implement the shared-memory model @Gamba. The original Watlab implementation we received at the beginning of the year still contained a broken version of this approach, so our work was more a rehabilitation than a development from scratch.

Regarding output, there's a small subtlety: writing and computation processes are not fully independent since they rely on the same data, namely the hydraulic variables. If the writing thread outputs concurrently while the finite-volume update is in progress, it leads to race conditions, as written values may vary between runs. To avoid this, careful synchronization is required. For example, computational threads can compute fluxes and source terms while cell data is being output since these intermediate values are not saved, but they must wait for the writing process to finish before altering the hydraulic variables during the finite-volume update. \
However, I/O operations are time-consuming in C++, which would cause significant delays for computational threads. Instead, writer threads make a local copy of the data to output using a preallocated buffer, which is faster. On the other hand, synchronization relies on mutexes: when launched, writers lock a mutex to indicate they intend to buffer cell data. Once done, they release the mutex, signaling that the backup copy is ready and proceed to write to files. Meanwhile, after computing fluxes and source terms, the finite-volume threads try to lock the same mutexes and will wait if writers have not yet finished buffering.

Concerning OpenMP loops, OpenMP provides several scheduling policies that can be passed to the compiler using the schedule(...) keyword in the directive. #text(fill: purple, [
  to do:
  - explain scheduling policies
  - compare scheduling policies in depth
  - scheduling allows for better load balance
  - dynamic scheduling may be good for flux computation to differentiate cell and dry cells
  - but for FV update no divergence thus maybe better static scheduling ?
  - verify that guided is the best
])

Finally, we slightly modified the implementation of the minimum computation. The original approach parallelized the loop over cells using OpenMP, with each thread storing intermediate results in a thread-local variable before merging them to find the global minimum. Since loop iterations are distributed across OpenMP threads, this acts like a domain subdivision, although the cells within each local region may not be contiguous. However, the merging strategy was suboptimal: each thread compared its result with a global variable inside a critical section, making the merging inherently sequential with linear complexity in the number of threads.

This can be improved using a parallel reduction, which resembles a tournament: first, threads form pairs and compare values in parallel, then winners form new pairs and repeat the process until one thread remains. This reduces the global minimum in $log_2(T)$ steps instead of $T$, where $T$ is the number of threads. An illustrative diagram of the reduction strategy is shown in @reduction. While this optimization may have little impact with the small number of cores typical in modern CPUs, it becomes significant for GPU implementations with many more cores. For example, 2560 parallel processes would require only 12 reduction rounds.

#import "@preview/fletcher:0.5.2" as fletcher: diagram, node, edge
#figure(
  scale( 92.5%, 
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

  node((0, 0), [13], name: <13>),
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

)), caption: [Minimum reduction]
)<reduction>

Fortunately, OpenMP provides built-in support for parallel reduction via the reduction keyword, abstracting implementation details and simplifying the code, as shown in the following pseudocode:
```cpp 
#pragma omp parallel for reduction(min:tmin)         
for (int i = 0; i < nCells; i++) {
  if (Cell[i].tmin < tmin) tmin = Cell[i].tmin;
}
```
The updated structure of the final parallel implementation is shown in @hydroflow_parallel.

#let light_blob(pos, label, w, tint: white, ..args) = node(
	pos, align(center, label),
	width: w,
	fill: tint.lighten(90%),
	stroke: 1pt + tint.lighten(30%),
	corner-radius: 5pt,
	..args,
)

#let blob(pos, label, w, tint: white, ..args) = node(
	pos, align(center, label),
	width: w,
	fill: tint.lighten(70%),
	stroke: 1pt + tint.darken(20%),
	corner-radius: 5pt,
	..args,
)

#figure(placement: auto, diagram(
	spacing: 8pt,
	cell-size: (8mm, 10mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
  debug: 0,

  let pos = 0,
  blob((0, pos -1.25), [Initialization], 35mm, tint: gray, name: <h2d>),

  blob((0, pos), [Time to output ?], 35mm, tint: gray, name: <if>),

  let side = pos,
  side += 1,
  blob((-.8, side), [Has previous output finished ?], 60mm, tint: gray, name: <yes>),
  side += 1.3,
  edge("-|>"),
  blob((-.8, side), [Buffer data], 25mm, tint: green, name: <save>),
  side += 1.3,
  edge("-|>"),
  blob((-.8, side), [Write data], 25mm, tint: green, name: <write>),
  
  pos += 1.5,
  light_blob((0+.05, pos), [ $ quad$], 47mm, tint: blue, name: <last_flux>),
  pos += .15,
  light_blob((0+.025, pos), [ $ quad$], 47mm, tint: blue),
  pos += .15,
  blob((0, pos), [$bold(F)_j^*$ #h(.5em) *for each* interface ], 47mm, tint: blue, name: <flux>),

  pos += 1.3,
  light_blob((0.05, pos), [$quad$], 35mm, tint: blue),
  pos += .15,
  light_blob((0.025, pos), [$quad$], 35mm, tint: blue),
  pos += .15,
  blob((0, pos), [$bold(S)_i^*$ #h(.5em) *for each* cell], 35mm, tint: blue, name: <update>),

  pos += 1.3,
  blob((0, pos), [Has data been buffered ?], 50mm, tint: gray, name: <buf>),
  pos += 1.5,

  light_blob((0.05, pos), [$quad$], 110mm, height: 9mm, tint:blue),
  pos += .15,
  light_blob((0.025, pos), [$quad$], 110mm, height: 9mm, tint:blue),
  // blob((0, 5.80 + .3), [$bold(U)_i^(n+1) = bold(U)_i^n - (Delta t)/A_i sum bold(F)^*_(i,j) n_(i,j) L_(i,j) + bold(S)_i^* Delta t$ #h(.5em) *for each* cell], 100mm, tint: blue, name: <min>),
  pos += .15,
  blob((0, pos), [$bold(U)_i^(n+1) = bold(U)_i^n - (Delta t \/ abs(cal(C)_i)) sum_(j) bold(T)^(-1)_j bold(F)^*_j  L_j + bold(S)_i^* Delta t$ #h(.5em) *for each* cell], 110mm, tint: blue, height: 9mm, name: <min>),

  pos += 1.5,
  light_blob((0.05, pos), [$quad$], 37.5mm, height: 9mm, tint: red),
  pos += .15,
  light_blob((0.025, pos), [$quad$], 37.5mm, height: 9mm, tint: red),
  // blob((0, 7.35 + 2*.15), [ $Delta t = min (Delta x)/(abs(u_i) + c_i)$], 35mm, tint: red, name: <d2h>),
  pos += .15,
  blob((0, pos), [$Delta t = min_i ( (Delta x)/(abs(u) + c) )_i$], 37.5mm, height: 9mm, tint: red, name: <red>),

  pos += 1.65,
  blob((0, pos), [$t >= t_"end"$ ?], 35mm, tint: gray, name: <d2h>),
  pos += 1.3,
  blob((0, pos), [Termination], 35mm, tint: gray, name: <end>),

  edge(<h2d>, <if>, "-|>"),
  edge(<flux>, (0., 2.85), "-|>"),
  edge(<update>, <buf>, "-|>"),
  edge(<min>, (0, 7.65), "-|>"),
  edge(<if>, (0, .8+.45), "-|>", label: [no], label-side: left),
  edge(<if>, <yes>, "..|>", corner: left),
  node((-0.5, -.25), align(center, [yes])),
  //node((0.075, .5), align(center, [no])),

  edge((-1.46, .5 + .2), (-1.47, 1.1 + .2), "<|-", bend: -120deg, label: [no]),
  let shift = 1.25,
  edge((.405, 3.15 + shift), (.415, 3.75 + shift), "<|-", bend: 120deg, label: [no]),

  edge(<d2h>,"r,uuuuuuuuuu,l","--|>"),
  edge(<red>, <d2h>, "-|>", label: [$t = t + Delta t$], label-side: left),

  edge(<buf>, (0, 5.85), "-|>", label: [yes], label-side: left),
  edge(<d2h>, <end>, "-|>"),

  let off = .4,
  edge((-.8, 3.5 + off), (-.8, 4 + off), "-"),
  edge((-.8, 4 + off), (-.8, 4.5 + off), "--")
 
), caption: [Updated program structure of the parallel implementation]) <hydroflow_parallel>

A finir