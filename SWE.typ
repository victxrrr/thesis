#import "@preview/fancy-units:0.1.1": unit

#let uu = math.text(fill: black)[$bold(U)$]
#let ff = math.text(fill: black)[$bold(F)$]
#let ff = math.text(fill: black)[$bold(F)(bold(U))$]
#let gg = math.text(fill: black)[$bold(G)(bold(U))$]
#let ss = math.text(fill: black)[$bold(S)(bold(U))$]

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


The Watlab hydraulic simulator solves the two-dimensional shallow water equations (SWE), which describe depth-averaged mass and momentum conservation in a horizontal plane. These equations neglect vertical velocities, making them suitable for flood modeling where horizontal flow dominates. They are expressed in conservative vector form as
$
(partial uu)/(partial t) + (partial ff)/(partial x) + (partial gg)/(partial y) = ss
$ <SWE>
where
$
uu = vec(h, q_x, q_y) quad 
ff = vec(q_x, q_x^2/h + 1/2 g h^2, (q_x q_y)/h) quad 
gg = vec(q_y, (q_x q_y)/h, q_y^2/h + 1/2 g h^2) quad 
ss = vec(0, g h(S_(0 x) - S_(f x)), g h(S_(0 y) - S_(f y)))
$
Here, $h thin [#unit[L]]$ is the water depth, and $q_x = u h thin [#unit[L^2 /s]]$, $q_y = v h thin [#unit[L^2 / s]]$ are the unit discharges in the $x$ and $y$ directions, respectively, with velocity components $u$ and $v$. Furthermore, the bed slope effects are modeled as
$
  S_(0 x) = - (partial z_b) / (partial x) wide S_(0 y) = - (partial z_b) / (partial y)
$ 
where $z_b thin [#unit[L]]$ is the bed elevation. Friction losses are given by
$
  S_(f x) = (n^2 u sqrt(u^2 + v^2))/(h^(4/3)) wide S_(f y) = (n^2 v sqrt(u^2 + v^2))/(h^(4/3))
$
where $n$ is the Manning's roughness  coefficient.