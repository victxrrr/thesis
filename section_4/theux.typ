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

#subpar.grid(
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
    [Theux], [XXX], [XXX], [XXX],
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
      [Theux],
    ),
    [$t_"start"$ [#unit[s]]], [7], [],
    [$t_"end"$ [#unit[s]]], [60], [],
    [$sigma$ [#unit[-]]], [0.9], [],
    [$Delta t_"pics"$ [#unit[s]]], [1], [],
    [$Delta t_"gauges"$ [#unit[s]]], [1], [],
    [$Delta t_"sections"$ [#unit[s]]], [1], [],
    [$Delta t_"enveloppes"$ [#unit[s]]], [1], []
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
