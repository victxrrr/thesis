
=== Toce case study

To assess the performance of each version presented in the previous subsections, we recorded the mean execution time of the Toce case study over 100 runs, discarding 10 warm-up executions (@bench_cpu). Note that all parallel versions use 14 OpenMP threads, matching the physical number of cores of our processor. First, we observe that reordering the mesh slightly reduces execution time regardless of parallelism. Then, we see that the first attempt at a deterministic OpenMP enabled version introduced significant overhead compared to the initial parallel implementation based on locks. While this was mitigated by converting member variables to local ones when possible, the second attempt is clearly faster and further reduces execution time. The lowest bar corresponds to our final parallel version, which includes all the presented features and will be referred to as the parallel version of Watlab from now on.

#figure(placement: auto,
  box(image("../img/bench_cpu2.svg"), stroke: none,
    clip: true,
    inset: (top: -9pt, bottom: -9pt, left: -12pt, right: -0pt)),
  caption: [Comparison of serial and parallel versions using 14 threads (Toce)
  ]
)<bench_cpu>

#import "@preview/fancy-units:0.1.1": unit, qty
To further assess the potential gains brought by our memory optimization in the flux function, we show the profiling update in the Roofline model in @flux_RL. We observe that the arithmetic intensity has increased.
Subsequently, the arithmetic throughput increases by #qty[41.47][%] percent, reducing execution time by #qty[43.78][%]. The peak bandwidths differ from the previous figure as we now consider all 14 cores of our processor.

#figure(placement: auto,
  image("../img/flux_RL.svg"),
  caption: [Comparison of `HydroFluxLHLLC` roofline analysis
  ]
)<flux_RL>

Finally, we inspect the impact of varying the number of OpenMP threads on the measured elapsed time. The measurements appear in @cpu_threads. As the thread count increases, execution time falls until all 14 physical cores are used. The Intel Core i7 13700H we use has 6 performance cores that support 12 logical threads via Intel Hyperthreading. By default OpenMP can use up to 20 threads. However, performance with 20 threads is worse than with 4. In that case the total concurrent threads can reach 24 when outputs are recorded, exceeding available resources and forcing interleaved execution. With 16 threads the results vary widely: one run may be very fast, another much slower.

#figure(placement: auto,
  box(
    image("../img/threads2.svg"),
    clip: true,
    inset: (top: -9pt, bottom: -9pt, left: -11pt, right: -22pt),
    stroke: none
  ),
  caption: [Impact of the number of OpenMP threads on the execution time (Toce)
  ]
)<cpu_threads>

#show table.cell.where(y: 0): strong
#set table(
  stroke: (x, y) => if y == 0 {
    (bottom: 0.7pt + black)
  },
  align: (x, y) => (
    if x > 0 { center }
    else { left }
  )
)

#figure(
  table(
  columns: 8,
  table.header(
    [Threads],
    [2],
    [4],
    [8],
    [12],
    [14],
    [16],
    [20]
  ),
  [$"Speedup"_"serial"$], [$2.93$], [$5.31$], [$7.37$], [$7.82$], [$7.88$], [$7.26$], [$4.42$],
) ,
  gap: .75em,
  caption: [Speedup factors with respect to the serial implementation (Toce)
],
)<cpu_SU>

#let unbold(it) = text(weight: "thin", it)

With these measurements we can also compute the speedup factors relative to the sequential version (@cpu_SU) to analyze scalability. The program scales fairly well up to 8 threads. Beyond that, using more threads increases performance only slightly. This may be due to the small scale of the case study, which does not generate enough workload to offset thread spawning overhead.
To gain a better understanding, we used another tool developed by Intel Corporation, namely Intel VTune. We launched a threading analysis on the parallel program with different number of used OpenMP threads to investigate the scalability behavior. This analysis reports various metrics such as:
/ _#unbold[Effective CPU utilization]_ : Percentages of the wall-clock time during which each specific number of CPU cores was simultaneously utilized.
/ _#unbold[Thread oversubscription]_ : Percentage of CPU time spent with more simultaneously active threads than there are logical cores available on the system.
/ _#unbold[Wait time with poor CPU utilization]_ : Per-thread idle time spent waiting on blocking or synchronization APIs.
/ _#unbold[Spin and overhead time]_ : Time spent in active but unproductive CPU usage due to busy-waiting or overhead from synchronization and threading libraries (e.g., OpenMP thread creation and destruction).
We profiled the parallel executable using 4, 16, and 20 OpenMP threads to compare the recorded metrics and understand the poor scalability. First, we show in @histo the distribution of simultaneously utilized CPU cores for each configuration.

#figure(placement: auto,
  box(
    image("../img/vtune.svg"),
    clip: true,
    inset: (top: -9pt, bottom: -9pt, left: -10pt, right: -10pt),
    stroke: none
  ),
  caption: [Distributions of effective CPU utilization
  ]
)<histo>

Let us first look at the upper histogram corresponding to the execution with 4 OpenMP working threads. We see that most of the execution time is spent with 4 active cores. It can reach 5 or 6 when outputs need to be written in parallel. The bar at 3 likely corresponds to load imbalance situations, where one thread finishes earlier than its coworkers. The bar at 1 corresponds to sequential parts of the program, and 0 corresponds to idle time.

When we look at the results with 16 threads, things become interesting. Similarly, we would expect a peak at 16, with some outlier bars between 17 and 20 for output threads. Instead, we see that most of the execution time is spent with 14 to 16 CPUs utilized simultaneously. We originally thought this might again be due to some form of load imbalance.

To gain further insight, we ran the simulation without requesting any outputs, so that only the OpenMP threads remained. The situation becomes completely different. Now, we clearly see a peak at 16, and the peaks at 13, 14, and 15, likely corresponding to uneven workload distribution among threads, are actually very small. Therefore, the suboptimal utilization of logical cores in the original execution seems to be caused by the parallel output operations, which interfere with the number of active OpenMP threads.
With 20 OpenMP working threads, the situation is similar but even more pronounced.

Additional metrics are reported in @vtune. We see that when 16 threads are employed, disabling outputs significantly reduces wait and spin times#footnote[The percentage indicates the share in total CPU time.]. Still, overhead time remains higher than with 4 threads. This is not surprising, as OpenMP has more threads to create and synchronize. With 20 threads, we observe the same tendencies. In this case, we now observe oversubscription, as there are more software threads than available cores. This lack of resources results in a quarter of the CPU time during which some threads cannot execute. In general, the wait times without outputs decrease, as no more synchronization shown in @hydroflow_parallel is needed to avoid race conditions compared to the 4 thread execution.

#show table.cell.where(y: 0): strong
#set table(
  stroke: (x, y) => if y == 0 {
    (bottom: 0.7pt + black)
  } else if y == 1 or y == 2 or y==3  {
    (bottom: .35pt)
  },
  align: (x, y) => (
    if x > 0 { center }
    else { left + horizon }
  )
)

#figure(
  table(
  columns: 6,
  table.header(
    [Metric],
    [4],
    [16],
    [16 #super[free]],
    [20],
    [20 #super[free]]
  ),
  [Average effective CPU utilization $["threads"]$], [$4.209$], [$14.073$], [$15.230$], [$15.015$], [$18.628$],
  [Thread oversubscription $#unit[[s]]$],
  [$0$ \ (#qty[0][%])], [$0$ \ (#qty[0][%])], [$0$ \ (#qty[0][%])], [$29.751$ \ (#qty[25.6][%])], [$0.550$ \ (#qty[1.3][%])],
  [Wait time with poor CPU utilization $#unit[[s]]$], [$0.191$], [$0.548$], [$0.070$], [$1.080$], [$0.103$],
  [Spin and overhead time $#unit[[s]]$],
  [$0.070$ \ (#qty[0.4][%])], [$2.848$ \ (#qty[5.8][%])], [$0.240$ \ (#qty[0.8][%])], [$13.453$ \ (#qty[11.6][%])], [$1.140$ \ (#qty[2.6][%])],
) ,
  gap: .75em,
  caption: [Profiled metrics from Intel VTune threading analysis
],
)<vtune>

We conclude our analysis by stating that as the number of threads used increases, the parallel efficiency decreases. On one hand, this is due to the inherent sequential part of the program, which limits the maximum achievable speedup according to Amdahl's law (@amdahl). On the other hand, it is due to the output threads. They become a bottleneck as the flux and source term computations are completed faster. The master thread must then wait on the mutexes for output tasks to complete before iterating over the cells to update their hydraulic variables. Moreover, output threads seem to steal cores used by OpenMP workers, ultimately decreasing the effective utilization of the processor.

=== Square basin case study

As a final step, we recorded execution times for the large scale square basin case study to observe whether the parallel implementation behaves similarly. Because of the longer simulations, we restrict ourselves to 30 executions with 5 warmup runs.

#figure(placement: auto,
  box(
    image("../img/threads_basin.svg"),
    clip: true,
    inset: (top: -9pt, bottom: -9pt, left: -10pt, right: -6pt),
    stroke: none
  ),
  caption: [Impact of the number of OpenMP threads on the execution time (basin)
  ]
)<bench_basin>

@bench_basin shows that in this case, the mesh reordering enables a massive speedup, as the serial version becomes twice as fast. The scalability behaves as in the previous case study, the parallel efficiency rapidly decreases as the number of threads get large. The difference is that now, using 16 OpenMP workers is less variable and leads to minimal execution time.

#set table(
  stroke: (x, y) => if y == 0 {
    (bottom: 0.7pt + black)
  },
  align: (x, y) => (
    if x > 0 { center }
    else { left + horizon }
  )
)

#figure(
  table(
  columns: 8,
  table.header(
    [Threads],
    [2],
    [4],
    [8],
    [12],
    [14],
    [16],
    [20]
  ),
  [$"Speedup"_"serial"$], [$4.78$], [$7.39$], [$8.87$], [$9.80$], [$10.21$], [$10.47$], [$8.21$],
  [$"Speedup"_"serial + reordering"$], [$2.34$], [$3.62$], [$4.34$], [$4.80$], [$5.00$], [$5.13$], [$4.02$],
) ,
  gap: .75em,
  caption: [Speedup factors with respect to the serial implementation (basin)
],
)<basin_su>

We also investigated the resulting speedup factors. @basin_su shows that we cannot go further than 10 times faster than the serial version. Compared to the serial version with reordered mesh, the efficiency is even worse, as most of the speedup is obtained using only 4 threads. Again, we suspected the output tasks to cause idle times, overall increasing execution time. Therefore, we ran an output free simulation on the square basin. The recorded mean execution time is $2 #unit[m] 03.50 thin (plus.minus 0.15) thin #unit[[s]]$, thus very close. It seems that there is a clear limit to the acceleration of Watlab using CPU parallelism, regardless of the mesh size, that is dictated by the program architecture and the functional limits of processor hardware.

To further reduce execution times, it is necessary to explore alternative hardware solutions, such as GPUs or FPGAs, which have emerged in the HPC field over the past decades @Vestias.
Therefore, we decided to develop a GPU implementation of Watlab to pursue the work initiated in the previous thesis @Gamba and leverage the widespread presence of GPUs in consumer computers, originally designed for gaming. A functional and efficient GPU-enabled program would benefit many Watlab users.
