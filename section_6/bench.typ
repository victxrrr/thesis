/*

faire un tableau temps d'exec speedup vs Serial ET speedup vs best parallel

*/
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

#import "@preview/fancy-units:0.1.1": num, unit, qty

We begin benchmarking our GPU implementation by measuring the mean execution time on the Toce simulation, as in the previous chapter. Results are shown in @toce_timings. We also computed the obtained speedups with respect to the serial and parallel implementations, using 14 OpenMP threads and a reordered mesh for the latter.

#figure(placement: auto,
table(
  columns: 4,
  table.header([Version], [Mean Execution Time $[#unit[s]]$], [$"Speedup"_"serial"$], [$"Speedup"_"parallel"$]),
  [GPU], [$1.30 (plus.minus 0.03)$], [$12.43$], [$1.58$],
  [GPU (reordering)], [$1.28 (plus.minus 0.03)$], [$12.63$], [$1.61$]
),
caption: [Benchmarks of the GPU implementation on Toce case study]
)<toce_timings>