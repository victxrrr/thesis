#import "@preview/fancy-units:0.1.1": num, unit, qty, fancy-units-configure, add-macros
#import "@preview/subpar:0.2.2"
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

In @Testa2007, the authors described flash flood experiments conducted on a 1:100 scale physical model of the Toce River valley, built in concrete. An urban district made of several concrete block buildings was placed in the riverbed to simulate flooding in a populated area and study the complex flow patterns caused by water interactions. Multiple water depth gauges were installed to collect bathymetric data, and an electric pump controlled the inflow discharge, determining the flood intensity. Together, the topography, inflow, and gauge measurements form a dataset well-suited for validating mathematical flood models.

In our case, we use a mesh file based on this experimental setup, shown in @Toce.
The inflow enters the domain through the west boundary indicated in the figure and exits through
a transmissive boundary at the far end. Note the 20 aligned squares representing scaled models of buildings. Sediment transport is not considered in this case study.

#figure(placement: auto, gap: 0.3em,
    box(image("../img/toce.svg"), clip: true,
      inset: (top: -10pt, bottom: -6pt, left: -20pt, right: -23pt),),
    caption: [Mesh corresponding to the small-scale model of the Toce River]
)<Toce>

#figure(placement: auto, gap: .75em,
    box(image("../img/inflow.svg", width: 80%), clip: true,
      stroke: none,
      inset: (top: -8pt, left: -8pt, right: -8pt, bottom: -10pt)),
    caption: [Inflow hydrograph]
)<inflow>

The key properties of the mesh geometry are listed in @meshes. Notice that we generated another mesh, much larger, on the same domain by significantly reducing the mesh size. This results in a mesh with about 800 000 small triangles, which we call Toce _XL_. This geometry will be used in @poc_section, where we only need a large number of cells to leverage GPU computational power for toy examples. However, we will not run Watlab on it, as very small cells may cause inconsistencies. First, due to @CFL, which significantly reduces the acceptable step size. Second, it may lead to arithmetic precision loss because of the difference in order of magnitude between the numerical fluxes, source terms, hydraulic variables, and the geometric quantities related to the cells in @update.

Regarding simulation parameters, the CFL number is set to $sigma = 0.9$, and the simulation runs from $#qty[7][[s]]$ to $#qty[60][[s]]$. This choice is based on the boundary hydrograph provided with the dataset (@inflow). We also periodically generate pictures of the hydraulic variables and gauge measurements, with gauge positions matching those in @Testa2007 as described in @simulations. The gauge coordinates are shown in @Toce. We also recorded envelopes every second, which correspond to the maximum values of height and velocities for each computational cell. Finally, we recorded the discharge measurements over the inflow and outflow sections to exploit all output capabilities of the program.

// #figure(placement: none, gap: .75em,
//     box(image("../img/inflow.svg", width: 70%), clip: true,
//       stroke: none,
//       inset: (top: -8pt, left: -8pt, right: -8pt, bottom: -10pt)),
//     caption: [Inflow hydrograph]
// )<inflow>
//
#subpar.grid(placement: auto,
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
    [$Delta t_"gauges"$ [#unit[s]]], [1], [--],
    [$Delta t_"sections"$ [#unit[s]]], [1], [--],
    [$Delta t_"enveloppes"$ [#unit[s]]], [1], [1]
    ),
    gap: .75em,
    caption: [
    Simulation parameters
  ]), <simulations>,
  columns: 1,
  caption: [Case study descriptions],
  kind: table,
  numbering: n => numbering("1.1", ..counter(heading.where(level: 1)).get(), n),
  numbering-sub-ref: (..n) => {
    numbering("1.1a", ..counter(heading.where(level: 1)).get(), ..n)
  },
  gap: 1em
)
