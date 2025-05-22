
#show: body => {
  for elem in body.children {
    if elem.func() == math.equation and elem.block {
      let numbering = if "label" in elem.fields().keys() { "(1)" } else { none }
      set math.equation(numbering: numbering)
      elem
    } else {
      elem
    }
  }
}

We define the serial version of the code as a version of Watlab without any form of parallelism. As a side note, we clarify that this version does not correspond to the original one received at the beginning of the master thesis. On one hand, we corrected some minor bugs in the first weeks, including memory leaks, output irregularities, and logic inconsistencies. On the other hand, the original version still contained remnants of parallelism and synchronization for output tasks, except for pictures, inherited from the previous study @Gamba. We believe that a fully sequential, cleaner version that is also closer to the parallel implementations presented later is more relevant for comparison and assessment of our work's efficiency. Therefore, we refer to this version when speaking about the serial version. It fully follows the execution diagram of @hydroflow.

Thanks to our work in @ch2, where we related Watlab's architecture to the underlying governing equations it simulates, we already know that execution time increases with mesh size and the number of simulated time steps. More precisely, from @hydroflow we derive that the program's complexity is $Theta(T(N + M))$, with $T$ the number of time steps, $N$ the number of cells, and $M$ the number of interfaces. To illustrate and verify this theoretical analysis, we executed and profiled the serial version on the Toce river case study. Snapshots of the flow are shown in @snapshots. The first picture exhibits the dry start related to this case study, as the domain is initially empty. Water enters through the inflow boundary and propagates over time. Note that no friction term needs to be computed for dry cells, and no fluxes travel between two dry cells. As a result, this phase is faster to process, and parallelization or GPU use may not reach maximum efficiency because the computational load is low at the beginning of the simulation.

#let ins = -6.5mm
#figure(placement: none,
  grid(rows: 1, columns: (1fr, 1fr, 1fr), column-gutter: 0mm,
  box(image("../img/toce_8.png"), clip: true, inset: (left: ins, right: ins, bottom: ins/2), stroke: none),
  box(image("../img/toce_17.png"), clip: true, inset: (left: ins, right: ins, bottom: ins/2)),
  box(image("../img/toce_51.png"), clip: true, inset: (left: ins, right: ins, bottom: ins/2))
  ,
  grid.cell(colspan: 3,
    move(image("../img/cbar_toce.svg", width: 91%), dx: 0%)
  )),
  caption: [Snapshots from the Toce river simulation]
)<snapshots>

#import "@preview/fancy-units:0.1.1": unit, qty

We profiled the execution of the code using `gprof` @gprof and `gprof2dot` to visualize the results as a call tree. @tree shows this partial call graph, omitting functions that have little or no impact on the total computation time. The percentages shown reflect the share of each call, with the total measured CPU time being #qty[18.66][[s]]. It is clear that the execution time of the Watlab computational code is dominated by flux computations, which account for about #qty[73][%] of the total. The most time consuming step is the processing of inner interfaces, taking #qty[58][%]. The second most time consuming step is the finite volume update of the cells, followed by the computation of source terms and finally the time step. Output functions are not shown, as they are negligible in comparison.

#figure(placement: auto,
  image("../img/graph2.svg",width: 100%),
  caption: [Profiling results of hydroflow execution]
)<tree>

From the profiling data, we see that writing the envelope and pictures takes only #qty[0.02][%], while gauge and section measurements each take less than one hundredth of a percent and are therefore not captured in further detail by the profiling tools. It is no surprise that the computeFluxes method accounts for a large share of the time, as it is called 5390 times during the #qty[53][[s]] of simulation, compared to only 53 pictures taken. However, if we compute the percentage per call, we get #qty[0.0135][%] and #qty[0.0004][%] respectively. This confirms that I/O operations remain a task that can be handled efficiently. Since writing to a file is expected to grow linearly with the number of cells, these proportions should hold for larger mesh sizes.

The profiling tree also shows that the long execution times of the functions in the finite volume scheme come from the fact that each cell and interface needs to be processed independently. To speed up computations, it is quite intuitive to leverage parallelism and the multicore architecture of modern processors to process them concurrently and accelerate the whole program.

But what kind of speedup can we actually expect? Amdahl's law @Encyclopedia is a simple formula that helps predict the maximum expected speedup based on the sequential part of the program $f$ and the number of parallel processors
$P$. It is given by:
$
  S = 1/(f + (1-f)/P)
$<amdahl>
In our case, all steps of the finite volume scheme can be parallelized, and they account for #qty[95.37][%] of the total execution time. Depending on the number of processors, we obtain:
 $
   S(2) = 1.91 wide  S(4) = 3.51 wide S(8) = 6.04 wide S(16) = 9.44
 $
 We observe that the efficiency#footnote[In parallel computing, parallel efficiency measures the ratio of parallel speedup to the number of parallel processors. The scalability of the program is characterized by the evolution of the efficiency as the number of processors varies. Ideally, we would like to have a constant efficiency of 100% or, equivalently, a linear speedup.] fastly decreases as the number of processor increases. Of course, this estimate should not be seen as a very precise estimate, as it neglects factors such as interprocess communication, synchronization, and the overhead from thread initialization and scheduling. On the other hand, as we increase the simulated time, the cost of geometry parsing, which depends only on the mesh size, becomes smaller compared to the finite volume computations, and so does the sequential part. As a result, the achievable speedups should increase.
