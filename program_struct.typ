#import "@preview/fletcher:0.5.2" as fletcher: diagram, node, edge
#import fletcher.shapes: house, hexagon, pill, chevron, diamond
#import "@preview/cetz:0.3.1"

#let cal(it) = math.class("normal", box({
  show math.equation: set text(font: "DejaVu Math TeX Gyre", stylistic-set: 3)
  $#math.cal(it)$
}) + h(0pt))

Based on the discretization scheme of the governing equations, Watlab's program structure is straightforward to understand.

To prevent confusion, we first provide a high-level overview of the program architecture. Watlab is primarily divided into two distinct parts, written in different languages for different purposes. The first part handles preprocessing and postprocessing tasks such as mesh parsing, boundary condition setup, and result visualization, all implemented in Python. Most hydraulic studies conducted by researchers or external users are performed through this Python API as a black box. However, the core computational code is written in C++, a compiled language known for its efficiency. The finite volume scheme is implemented in C++ using an object-oriented approach, producing a single executable after compilation. This binary reads input files containing geometry and simulation parameters from the Python interface and outputs hydraulic variables at user-specified time steps.

Watlab is publicly available @Watlab as a Python package and can be easily installed via `pip` @pip. When downloaded, only the Python files and compiled binaries are installed on the user's machine.

Our work primarily focuses on the computational code written in C++, though we may also modify the Python module if, for example, mesh reorganization is needed. A summary diagram of the high-level architecture is shown in @high. 
Also note that the C++ code may sometimes be referred as _Hydroflow_.

#let blob(pos, label, w, tint: white, ..args) = node(
	pos, align(center, label),
	width: w,
	fill: tint.lighten(60%),
	stroke: 1pt + tint.darken(20%),
	corner-radius: 5pt,
	..args,
)

#figure(placement: auto,
  move(
    diagram(
      spacing: 8pt,
      cell-size: (8mm, 10mm),
      edge-stroke: 1pt,
      edge-corner-radius: 5pt,
      mark-scale: 70%,
      debug: 0,

      node((0, -1.75), align(center, [Mesh file]), name: <mesh>),
      edge("-|>"),
      blob((0, -0.25), [*Watlab.py* \ Python API], 30mm, tint: gray, name: <watlab>),
      blob((0, 1.5), [*Binary*], 30mm, tint: gray, name: <binary>),
      edge("-|>"),
      node((0, 3), align(center, [Output files]), name: <output>),
      
      node((.5, .725), align(center, [Input files])),

      blob((-3.5, 1.5), [*Hydroflow* \ C++ source], 30mm, tint: gray, name: <hydroflow>),
      node((-1.8, 1.15), align(center, [_Compilation_])),

      node(enclose: ((-1, 4), (1, -2)), stroke: (paint: gray, dash: "dashed"), fill: none, corner-radius: 10pt),

      edge(<hydroflow>, <binary>, "--|>"),
      edge(<watlab>, <binary>, "-|>"),
      //edge(<mesh>, <binary>, "-|>"),

      node((0, -2.5), align(center, text(size: 12pt, fill: luma(30%), [_User side_])))
    )
  ),
  caption:  [High-level architecture]
)<high>

We now focus on the structure of the computational code, including the implementation of the finite volume scheme. The program begins by reading the provided geometry and instantiating objects representing the domain, cells, interfaces, and nodes. It then enters the main loop. \
At each iteration, the program first checks whether hydraulic variables need to be output. Watlab provides several data outputs, including hydraulic variables at user-specified gauges, the maximum water height in the domain, snapshots of hydraulic variables in each cell (_pictures_), and total discharge across interface sections. If output is required, it is processed first; otherwise, the domain is updated.\
The update process involves computing numerical fluxes at each interface, calculating source terms for each cell, and updating hydraulic quantities based on the FV scheme (@update). The computational dependencies between variables over time are illustrated in @dep. The next time step is then determined using the CFL condition (@CFL). If the updated simulation time exceeds the end time, the program terminates and cleans up the data. Otherwise, the time step is incremented, and the loop continues. An overview of the program structure is provided in @hydroflow.

#figure(placement: auto,
  cetz.canvas({
  import cetz.draw: *
  // Your drawing code goes here

  let clr1 = rgb(0, 121, 107)
  let clr2 = rgb(255, 111, 97)
  let clr3 = rgb("#7821ca")
  let light_clr1 = rgb(0, 121, 107, 80)
  let light_clr2 = rgb(255, 111, 97, 80)
  let light_clr3 = rgb("#c487fd")

  // grid((0,0), (9,8), help-lines: true)
  line((0,8), (1,8), mark: (end: "stealth", fill: black, scale: .75))
  content((1.25, 8.05),$x$)
  line((0,8), (0,7), mark: (end: "stealth", fill: black, scale: .75))
  content((0, 6.75), $t$)
  line((0,8, 0), (0,8, -1), mark: (end: "stealth", fill: black, scale: .75))
  content((0, 8, -1.35), $y$)
  
  line((1,7), (4, 7, -4), stroke: luma(70%))
  line((1,7), (9,7), stroke: luma(70%))
  line((9,7), (4,7,-4), stroke: luma(70%))
  line((5,7), (3.5,8))
  line((5,7), (7.5,8))
  line((7.5,8),(3.5,8))

  line((1,4), (9, 4), stroke: luma(70%))
  line((1,4), (4,4,-4), stroke: luma(70%))
  line((4,4,-4), (9,4), stroke: luma(70%))
  line((5,4), (3.5,5))
  line((5,4), (7.5,5))
  line((7.5,5),(3.5,5))

  line((1,1), (9, 1), stroke: luma(70%))
  line((1,1), (4,1,-4), stroke: luma(70%))
  line((4,1,-4), (9,1), stroke: luma(70%))
  line((5,1), (3.5,2))
  line((5,1), (7.5,2))
  line((7.5,2),(3.5,2))

  let dx = 0

  line((5.5,5), (5.25 + dx, 7.66), stroke: (dash: "dashed", paint: black))
  line((4.25,4.5), (5.25 + dx, 7.66), stroke: (dash: "dashed", paint: black))
  line((6.25,4.5), (5.25 + dx, 7.66), stroke: (dash: "dashed", paint: black))
  line((5.25 - .1,4.66), (5.25 + dx, 7.66), stroke: (dash: "dashed", paint: black))
  line((5.25 - .1,4.66), (5.25, 1.66), stroke: (dash: "dashed", paint: black))
  line((5.5,5), (5.25 + dx, 1.66), stroke: (dash: "dashed", paint: black))
  line((4.25,4.5), (5.25 + dx, 1.66), stroke: (dash: "dashed", paint: black))
  line((6.25,4.5), (5.25 + dx, 1.66), stroke: (dash: "dashed", paint: black))
  // line((2,2.9), (5.25, 1.66), stroke: (dash: "dashed", paint: black))
  // content((1.85, 3.1), $bold(S)^*_i$, anchor: "east")
  // line((5.25, 7.66), (1.88, 3.3), stroke: (dash: "dashed"))
  //line((5.25, 7.66), (1.88, 3.3), stroke: (dash: "dashed"))

  line((9.5,7.66), (9.5, 1.66), mark: (start: "stealth", end: "stealth", fill: black, scale: 0.75))
  content((9.9, 4.66), $Delta t$)

  dx = .1
  let w = .06
  let sq(center, clr) = rect(
    (center.at(0)-dx - w, center.at(1)-w),
    (center.at(0)-dx+w, center.at(1)+w),
    fill: clr,
    stroke: clr
  )

  dx = 0
  circle((5.5, 8, 0), fill: clr1, stroke: clr1, radius: 2pt)
  circle((4.25, 7.5, 0), fill: clr1, stroke: clr1, radius: 2pt)
  circle((6.25, 7.5, 0), fill: clr1, stroke: clr1, radius: 2pt)
  circle((5.25 + dx, 7.66, 0), fill: clr2, stroke: clr2, radius: 2pt)
  //sq((5.25, 7.66), clr3)
  circle((7, 7, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((3, 7, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((8.25, 7.5, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((2.25, 7.5, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((6.75, 8.5, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((4.75, 8.5, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((5.75 + dx, 8.33, 0), fill: light_clr2, stroke: light_clr2, radius: 2pt)
  //sq((5.75, 8.33), light_clr3)
  circle((7.25 + dx, 7.33, 0), fill: light_clr2, stroke: light_clr2, radius: 2pt)
  //sq((7.25, 7.33), light_clr3)
  circle((3.25 + dx, 7.33, 0), fill: light_clr2, stroke: light_clr2, radius: 2pt)
  //sq((3.25, 7.33), light_clr3)
  

  circle((5.5, 5, 0), fill: clr1, stroke: clr1, radius: 2pt)
  circle((4.25, 4.5, 0), fill: clr1, stroke: clr1, radius: 2pt)
  circle((6.25, 4.5, 0), fill: clr1, stroke: clr1, radius: 2pt)
  dx = .1
  circle((5.25 + dx, 4.66, 0), fill: clr2, stroke: clr2, radius: 2pt)
  sq((5.25, 4.66), clr3)
  circle((7, 1, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((3, 1, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((8.25, 1.5, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((2.25, 1.5, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((6.75, 2.5, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((4.75, 2.5, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  dx = 0
  circle((5.75 + dx, 2.33, 0), fill: light_clr2, stroke: light_clr2, radius: 2pt)
  //sq((5.75, 2.33), light_clr3)
  circle((7.25 + dx, 1.33, 0), fill: light_clr2, stroke: light_clr2, radius: 2pt)
  //sq((7.25, 1.33), light_clr3)
  circle((3.25 + dx, 1.33, 0), fill: light_clr2, stroke: light_clr2, radius: 2pt)
  //sq((3.25, 1.33), light_clr3)

  circle((5.5, 2, 0), fill: clr1, stroke: clr1, radius: 2pt)
  circle((4.25, 1.5, 0), fill: clr1, stroke: clr1, radius: 2pt)
  circle((6.25, 1.5, 0), fill: clr1, stroke: clr1, radius: 2pt)
  circle((5.25 + dx, 1.66, 0), fill: clr2, stroke: clr2, radius: 2pt)
  //sq((5.25, 1.66), clr3)
  circle((7, 4, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((3, 4, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((8.25, 4.5, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((2.25, 4.5, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((6.75, 5.5, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  circle((4.75, 5.5, 0), fill: light_clr1, stroke: light_clr1, radius: 2pt)
  dx = .1
  circle((5.75 + dx, 5.33, 0), fill: light_clr2, stroke: light_clr2, radius: 2pt)
  sq((5.75, 5.33), light_clr3)
  circle((7.25 + dx, 4.33, 0), fill: light_clr2, stroke: light_clr2, radius: 2pt)
  sq((7.25, 4.33), light_clr3)
  circle((3.25 + dx, 4.33, 0), fill: light_clr2, stroke: light_clr2, radius: 2pt)
  sq((3.25, 4.33), light_clr3)

  let xshift = - 3
  let yshift = - .5
  circle((.85 + xshift, 5.9 + yshift), fill: clr2, stroke: clr2, radius: 2pt)
  content((1.32 + xshift, 5.9 + yshift), $bold(U)_i$)
  circle((2 + xshift, 5.9 + yshift), fill: clr1, stroke: clr1, radius: 2pt)
  content((2.47 + xshift, 5.9 + yshift), $bold(F)^*_j$)
  //circle((3.15 + xshift, 5.9 + yshift), fill: clr3, stroke: clr3, radius: 2pt)
  sq((3.2 + xshift, 5.9 + yshift), clr3)
  content((3.57 + xshift, 5.9 + yshift), $bold(S)^*_i$)

  line((.5 + xshift, 6.4 + yshift), (3.1 + 1 + xshift, 6.4 + yshift), stroke: (thickness: .75pt))
  line((.5 + xshift, 5.4 + yshift), (3.1 +  1 + xshift, 5.4 + yshift), stroke: (thickness: .75pt))
  line((.5 + xshift, 6.4 + yshift), (.5 + xshift, 5.4 + yshift), stroke: (thickness: .75pt))
  line((3.1 + 1 + xshift, 6.4 + yshift), (3.1 + 1. + xshift, 5.4 + yshift), stroke: (thickness: .75pt))
  }),
  caption: [Dependencies]
)<dep>

#figure(placement: auto,
  diagram(
	spacing: 8pt,
	cell-size: (8mm, 10mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
  debug: 0,

  blob((0, -1.25), [Initialization], 35mm, tint: gray, name: <h2d>),

  blob((0, -0.), [Time to output ?], 35mm, tint: gray, name: <if>),
  blob((-.75, 0.8), [Write data], 30mm, tint: green, name: <yes>),

  blob((0, 1.5), [$bold(F)^*_j$ #h(.5em) *for each* interface ], 47mm, tint: blue, name: <flux>),

  blob((0, 2.75), [$bold(S)_i^*$ #h(.5em) *for each* cell], 35mm, tint: blue, name: <update>),

  blob((0, 4), [$bold(U)_i^(n+1) = bold(U)_i^n - (Delta t \/ abs(cal(C)_i)) sum_(j) bold(T)^(-1)_j bold(F)^*_j  L_j + bold(S)_i^* Delta t$ #h(.5em) *for each* cell], 110mm, tint: blue, height: 9mm, name: <min>),

  blob((0, 5.35), [$Delta t = min_i ( (Delta x)/(abs(u) + c) )_i$], 37.5mm, height: 9mm, tint: red, name: <red>),

  blob((0, 7), [$t >= t_"end"$ ?], 35mm, tint: gray, name: <d2h>),

   blob((0, 8.25), [Termination], 35mm, tint: gray, name: <end>),

  edge(<h2d>, <if>, "-|>"),
  edge(<flux>, <update>, "-|>"),
  edge(<update>, <min>, "-|>"),
  edge(<min>, <red>, "-|>"),
  edge(<red>, <d2h>, "-|>", label: [$t = t + Delta t$], label-side: left),
  edge(<if>, <flux>, "-|>"),
  edge(<if>, <yes>, "-|>", corner: left),
  edge(<yes>, <flux>, "-|>", corner: left),
  node((-0.5, -.25), align(center, [yes])),
  node((0.075, .65), align(center, [no])),

  edge(<d2h>,"r,uuuuuuu,l","--|>", label: [no]),
  edge(<d2h>, <end>, "-|>",label: "yes", label-side: left)
  ),
  caption: [Program structure]
)<hydroflow>