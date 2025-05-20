
To assess the performance of each version presented in the previous subsections, we recorded the mean execution time of the Toce case study over 100 runs, discarding 10 warm-up executions (@bench_cpu). Note that all parallel versions use 14 OpenMP threads, matching the physical number of cores of our processor. First, we observe that reordering the mesh slightly reduces execution time regardless of parallelism. Then, we see that the first attempt at a deterministic OpenMP enabled version introduced significant overhead compared to the initial parallel implementation based on locks. While this was mitigated by converting member variables to local ones when possible, the second attempt is clearly faster and further reduces execution time. The lowest bar corresponds to our final parallel version, which includes all the presented features and will be referred to as the parallel version of Watlab from now on.

#figure(placement: auto,
  image("../img/bench_cpu.svg"),
  caption: [
    Comparison of serial and parallel versions using 14 threads (Toce)
  ]
)<bench_cpu>

#import "@preview/fancy-units:0.1.1": unit, qty
To further assess the potential gains brought by our memory optimization in the Flux function, we show the profiling update in the Roofline model in @flux_RL. We observe that the arithmetic intensity has increased.
Subsequently, the arithmetic throughput increases by #qty[41.47][%] percent, reducing execution time by #qty[43.78][%]. The peak bandwidths differ from the previous figure as we now consider all 14 cores of our processor.

#figure(placement: auto,
  image("../img/flux_RL.svg"),
  caption: [
    Comparison of `HydroFluxLHLLC` benchmarks
  ]
)<flux_RL>

Finally, we inspect the impact of varying the number of OpenMP threads on the measured elapsed time. The measurements appear in @cpu_threads. As the thread count increases, execution time falls until all 14 physical cores are used. The Intel i7 13700H has 6 performance cores that support 12 logical threads via Intel Hyperthreading. By default OpenMP can use up to 20 threads. However, performance with 20 threads is worse than with 4. In that case the total concurrent threads can reach 24 when outputs are recorded, exceeding available resources and forcing interleaved execution. With 16 threads the results vary widely: one run may be very fast, another much slower.

#figure(placement: auto,
  image("../img/threads.svg"),
  caption: [
    Impact of the number of OpenMP threads on the execution time (Toce)
  ]
)<cpu_threads>

#show table.cell.where(y: 0, x: 0): strong
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
  [$"Speedup"_"serial"$], [$2.93$], [$5.31$], [$7.35$], [$7.79$], [$7.85$], [$7.20$], [$4.41$],
) ,
  gap: .75em,
  caption: [
  Speedup factors with respect to the serial implementation
],
)<cpu_SU>

With these measurements we can also compute the speedup factors relative to the sequential version (@cpu_SU) to analyze scalability. The program scales fairly well up to 8 threads. Beyond that, using more threads increases performance only slightly. This may be due to the small scale of the case study, which does not generate enough workload to offset thread spawning overhead. More likely, threads access data on the same cache lines, causing _false sharing_. Therefore, we examined the results from our larger scale case study to confirm those assumptions.

Due to technical constraints, the number of cores that comprise contemporary multicore processors is limited, thereby constraining the achievable speed-up of CPU-parallelized programs in accordance with Ahmdal's Law (REF). At the time of this writing, the latest generation of Intel Core i9 processors for consumers has a maximum of 24 cores. Consequently, to further reduce execution times, it is necessary to explore alternative hardware solutions, such as Graphic Processing Units (GPUs) or Field Programmable Gate Arrays (FPGAs), which have emerged in the HPC field over the past decades @Vestias.

We decided to develop a GPU implementation of Watlab to pursue the work initiated in the previous thesis @Gamba on the previous and leverage the widespread presence of GPUs in consumer computers, originally designed for gaming. A functional and efficient GPU-enabled program would benefit many Watlab users.
