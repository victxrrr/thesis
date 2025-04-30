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
    [Theux], [XXX], [XXX], [XXX],
  ) , 
    caption: [
    Geometric description of meshes
  ]), <meshes>,
  figure(
    table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    table.header(
      [Case study],
      [$t_"start"$ [#unit[s]]],
      [$t_"end"$ [#unit[s]]],
      [$sigma$ [#unit[-]]],
      [$Delta t_"pics"$ [#unit[s]]],
      [$Delta t_"gauges"$ [#unit[s]]],
    ),
    [Toce], [7], [60], [0.9], [1], [1],
    [Theux], [XXX], [XXX], [XXX],
    ), 
    caption: [
    Simulation parameters
  ]), <simulations>,
  columns: 1,
  caption: [Case study descriptions],
  kind: table
)
