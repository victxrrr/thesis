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

#import "@preview/subpar:0.2.2"
#import "@preview/fancy-units:0.1.1": num, unit, qty, fancy-units-configure, add-macros

#subpar.grid(placement:auto,
  figure(
    table(
    columns: (1fr, 1fr, 1fr, 1fr),
    table.header(
      [Case study],
      [\# Nodes],
      [\# Interfaces],
      [\# Cells]
    ),
    [Toce], [6 716], [19 731], [12 996],
    [Toce _XL_], [406 115], [1 214 591], [808 457],
    [Square basin], [290 132], [868 393], [578 262],
  ) ,
    gap: .75em,
    caption: [
    Geometric description of meshes
  ],
  ), <meshes>,
  figure(
    table(
    columns: (1fr, 1fr, 1fr),
    table.header(
      [Parameter],
      [Toce],
      [Square basin],
    ),
    [$t_"start"$ [#unit[s]]], [7], [0],
    [$t_"end"$ [#unit[s]]], [60], [60],
    [$n$ [#unit[-]]], [0.0162], [0.06],
    [$sigma$ [#unit[-]]], [0.9], [0.95],
    [$Delta t_"pics"$ [#unit[s]]], [1], [1],
    [$Delta t_"gauges"$ [#unit[s]]], [1], [],
    [$Delta t_"sections"$ [#unit[s]]], [1], [],
    [$Delta t_"enveloppes"$ [#unit[s]]], [1], [1]
    ),
    gap: .75em,
    caption: [
    Simulation parameters
  ]), <simulations>,
  columns: 1,
  caption: [Case study descriptions],
  kind: table,
  numbering: n => {
    let h1 = counter(heading).get().first()
    numbering("1.1", h1, n)
  }, gap: 1em
)

The mesh of the previous case study contains tens of thousands of cells.
In terms of computational load, it is quite reasonable. As we investigate solutions that
logically divide the computational domain into smaller parts to be solved concurrently,
we need to ensure each processor receives sufficient workload to assess the real benefits
of our approach. Therefore, we rely on a second, larger-scale case study.

This case involves an artificial square basin with one inlet, where an inflow discharge
of $#qty[400][m^3 / s]$ is imposed, and one outlet through which water can escape. An overview of the geometry is given in @basin. The initial water
level is uniformly set to $#qty[1][m]$ across the domain, making this a fully wet simulation. The large scale
results from the basin's considerable dimensions, measuring $#qty[125][m]$ by $#qty[125][m]$.
Using cells with a characteristic length of $#qty[0.5][m]$, the resulting mesh contains a
significant number of geometrical elements, as shown in @meshes.

#figure(placement: auto,
  image("../img/basin.svg"),
  caption: [Square basin geometry]
)<basin>

The simulation runs for 60 seconds, with a picture and envelope generated each second. Some of them are shown in @basin_pics.

#let ins = -1.5mm
#figure(
  grid(rows: 3, columns: (1fr, 1fr), column-gutter: 0mm, row-gutter: 0mm,
  box(image("../img/basin_5.png"), clip: true, inset: (left: ins, right: ins, top: 2*ins, bottom: 2*ins)),
  box(image("../img/basin_33.png"), clip: true, inset: (left: ins, right: ins, top: 2*ins, bottom: 2*ins)),
  grid.cell(colspan: 2,
  box(image("../img/basin_59.png", width: 55%), clip: true, inset: (left: ins, right: ins, top: 2*ins, bottom: 2*ins))
  ),
  grid.cell(colspan: 2,
    move(image("../img/bar.svg", width: 60%), dx: 1.5%)
  )
  )
  ,
  caption: [Snapshots from the square basin simulation]
)<basin_pics>

