#import "@preview/cetz:0.3.1"

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

#let cal(it) = math.class("normal", box({
  show math.equation: set text(font: "DejaVu Math TeX Gyre", stylistic-set: 3)
  $#math.cal(it)$
}) + h(0pt))

To solve @SWE, we divide the computational domain into smaller two-dimensional _cells_, denoted by $cal(C)_i$ (@cell), and assume the hydraulic variables in $bold(U)$ remain constant within each cell. The segments forming the boundaries are called _interfaces_, and the cells are typically triangular. Finally, the cell vertices are called _nodes_, and the collection of cells, interfaces, and nodes forms a _mesh_ used to solve the shallow water equations.

#figure(placement: auto,
  scale(75%,
  cetz.canvas(
    {
      import cetz.draw: *

      let light = luma(70%)

      //grid((-8,-5), (8,4), help-lines: true)
      // line((-8,0), (8,0))
      // line((0,-5), (0,4))
      // 

      let up = (-4, -2)
      let length = 2
      let padding = .33
      let corner = (up.at(0), up.at(1)-length)
      let right = (corner.at(0)+length, corner.at(1))
      line(corner, up, mark: (end: "stealth", fill: black, scale: .75))
      line(corner, right, mark: (end: "stealth", fill: black, scale: .75))
      content((up.at(0), up.at(1) + padding), text([$x$], size: 14pt))
      content((right.at(0) + padding, right.at(1)), text([$y$], size: 14pt))

      let A = (3, 0)
      let B = (0, 2.25)
      let C = (-1.25, -1.25)
      line(A, B)
      line(A, C)
      line(B, C)

      line(A, (1, -3.75), stroke: light)
      line((1, -3.75), C, stroke: light)

      line(C, (-3.5, .5), stroke: light)
      line((-3.5, .5), B, stroke: light)
      content((0.58333, .33333), text([$cal(C)_i$], size: 18pt))

        // Midpoint of segment AB
      let mid = ((A.at(0) + B.at(0)) / 2, (A.at(1) + B.at(1)) / 2)

      // Length of normal vector
      let len = 1.5

      // Compute the endpoint of the normal vector
      let end = (mid.at(0) + len * 0.6, mid.at(1) + len * 0.8)

      // Draw the normal vector with an arrow
      line(mid, end, mark: (end: "stealth", fill: black, scale: .75), name: "normal")
      content((2.7, 2.7), text([$bold(n)_j$], size: 14pt))

      len = 0.6
      let endA = (A.at(0) + len * .6, A.at(1) + len * .8)
      let endB = (B.at(0) + len * .6, B.at(1) + len * .8)

      line(A, endA, stroke: (dash: "dashed", paint: black))
      line(B, endB, stroke: (dash: "dashed", paint: black))
      line(endA, endB, mark: (start: "stealth", end: "stealth", fill: black, scale: 0.5), stroke: .75pt, name: "length")
      content((3.25, 1.25), text([$L_j$], size: 15pt))

      line((0.58333 + .5, 0.33333), (4, -1), stroke: (dash: "dashed"))
      content((5.65, -1.25), text([$bold(U)_i = vec(h, q_x, q_y)_i$], size: 16pt))

    }
  )),
  caption: [Cell geometry
  ]
)<cell>


#figure(placement: auto,
  scale(75%,
  cetz.canvas(
    {
      import cetz.draw: *

      let light = luma(70%)

      //grid((-5,-5), (10,4), help-lines: true)
      // line((-5,0), (10,0))
      // line((0,-5), (0,4))
      // 

      let up = (-4, -1)
      let length = 2
      let padding = .33
      let corner = (up.at(0), up.at(1)-length)
      let right = (corner.at(0)+length, corner.at(1))
      let behind = (corner.at(0), corner.at(1), -length)
      line(corner, up, mark: (end: "stealth", fill: black, scale: .75))
      line(corner, right, mark: (end: "stealth", fill: black, scale: .75))
      line(corner, behind, mark: (end: "stealth", fill: black, scale: .75))
      content((up.at(0), up.at(1) + padding), text([$t$], size: 14pt))
      content((right.at(0) + padding, right.at(1)), text([$x$], size: 14pt))
      content((behind.at(0), behind.at(1), behind.at(2) - 1.5*padding), text([$y$], size: 14pt))

      line((-1.5,-2.5), (3.5, -3), stroke: light)
      line((-1.5,-2.5), (2, -1), stroke: light)
      line((5,0), (2, -1), stroke: (paint: light, dash: "dashed"))
      line((5,0), (7, -1.25), stroke: (paint: light, dash: "dashed"))
      line((2,-1), (3.5,-3))
      line((7,-1.25), (3.5,-3))
      line((7,-1.25),(2, -1), stroke: (dash: "dashed"))
      line((9.5, -2.5), (7, -1.25), stroke: light)
      line((9.5, -2.5), (3.5, -3), stroke: light)

      let offset = 3.25
      line((2,-1+offset), (3.5,-3+offset))
      line((7,-1.25+offset), (3.5,-3+offset))
      line((7,-1.25+offset),(2, -1+offset))

      line((2, -1), (2, -1+offset))
      line((3.5, -3), (3.5, -3+offset))
      line((7, -1.25), (7, -1.25 + offset))

      let shift = .5
      line((7+shift, -1.25), (7+shift, -1.25 + offset), mark: (start: "stealth", end: "stealth", fill: black, scale: 0.5))
      line((7, -1.25), (7+shift, -1.25), stroke: (dash: "dashed"))
      line((7, -1.25+offset), (7+shift, -1.25+offset), stroke: (dash: "dashed"))

      content((7 + 2*shift, -1.25 + 0.5 * offset), text([$Delta t$], size: 14pt))
      content((4.5, -.25), text([$Omega_i$], size: 18pt))
    }
  )),
  caption: [Control volume
  ]
)<control>

The finite volume formulation follows from conservation laws imposed on the control volumes $Omega_i := cal(C)_i times Delta t$ (@control). Mathematically, this is expressed as:
$
  integral_(Omega_i) (
    (partial bold(U))/(partial t) + (partial bold(F)(bold(U)))/(partial x) + (partial bold(G)(bold(U)))/(partial y) 
  ) d Omega
  = 
  integral_(Omega_i)
  bold(S)(bold(U)) d Omega
$ <int>
The left-hand side of @int represents the divergence of the vector
$
  bold(H) = vec(bold(F), bold(G), bold(U))
$
in the $(x, y, t)$ space. Applying the Green-Gauss theorem, we transform the volume integral into a surface integral:
$
  integral_(Omega_i) (nabla dot bold(H)) thin  d Omega = integral.cont_(partial Omega_i) ( bold(H) dot bold(n)) thin d S
$
where $bold(n)$ is the outward normal vector. To compute the integral, we sum the contributions from each face of the control volume. \
Since Watlab handles *unstructured* meshes, determining flux contributions at interfaces is nontrivial. We use a $*$ superscript for time-averaged quantities over $Delta t$ and denote the area of $cal(C)_i$ as $abs(cal(C)_i)$. Instead of directly computing $ bold(F)^*$ and $bold(G)^*$ at interfaces, we solve a locally equivalent problem using the basis transformation:

$
  overline(bold(U)) := bold(T) bold(U) = mat(1, 0, 0; 0, n_(x), n_(y); 0, -n_(y), n_(x))
  vec(h, u h, v h) = vec(h, u_n h, v_t h)
$
where $bold(n) = (n_x, n_y)$ is the normal vector of a cell interface. Solving @SWE in the $(x_n, y_t)$ basis yields:
$
  (partial overline(bold(U)))/(partial t) + (partial bold(F) (overline(bold(U))))/( partial x_n)
  = bold(T) bold(S)
  wide "with" wide
  bold(F)(overline(bold(U))) = vec(u_n h, u_(n)^2 h + 1/2 g h^2, u_n v_t h)
$
Multiplying by $bold(T)^(-1)$ recovers the average flux across the interface in global coordinates, i.e. an appropriate summation of vertical and horizontal flux contributions, yielding:
$
  integral.cont_(partial Omega_i) ( bold(H) dot bold(n)) thin d S 
  = mat(bold(F), bold(G), bold(U))^(n+1)_i vec(0, 0, 1) abs(cal(C)_i) + mat(bold(F), bold(G), bold(U))^n_i vec(0, 0, -1) abs(cal(C)_i) \
  + Delta t sum_(j) bold(T)^(-1)_j bold(F)^*_j (overline(bold(U))_i^n) L_j
$
The right-hand side of @int integrates as:
$
    integral_(Omega_i) bold(S)(bold(U)) thin d Omega = bold(S)^*_i Delta t abs(cal(C)_i)
$
Combining and rearranging the terms, the discrete form of @SWE corresponding to the finite volume explicit scheme is given by
$
  bold(U)_i^(n+1) = bold(U)_i^n - (Delta t) / (abs(cal(C)_i)) sum_(j) bold(T)^(-1)_j bold(F)^*_j  L_j + bold(S)_i^* Delta t
$<update>
The key challenge in this scheme is computing the numerical fluxes $bold(F)^*_j$ at cell interfaces while ensuring mass and momentum conservation @Sandra. Since conserved variables are piecewise constant, discontinuities at interfaces create Riemann problems. In practice, Watlab reconstructs numerical fluxes using the Harten-Lax-van Leer-Contact (HLLC) solver. A full discussion of this solver is beyond this introduction, but one may retain that it is computationally heavier than finite volume updates, as confirmed by Watlab profiling in the next sections. Flux computation may also vary at boundary interfaces, depending on boundary conditions.

Additionally, Watlab implements a morphodynamic model based on the Exner equation. Since this module does not alter the program's core architecture, only increasing computational cost, it is not discussed further. More details are available in the official documentation @Watlab.

Finally, as this scheme is explicit, the time step must be carefully chosen to ensure numerical stability. The Courant-Friedrichs-Lewy (CFL) condition dictates:
$
  Delta t^n = min_i ( (Delta x)/(abs(bold(u)^n) + c^n) )_i
$<CFL>
where   
$ 
Delta x_i = 2(abs(cal(C)_i)) / abs(partial cal(C)_i) wide abs(bold(u)^n_i) = sqrt((u_i^n)^2 + (v_i^n)^2) wide c_i^n = sqrt(g h_i^n )
$

