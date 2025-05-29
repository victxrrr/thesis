/*
la parallelisation entraine du non detemrinisme du aux changement d'ordre des ops --> Eijkhout

a faire:

si je mets des 0 dans la cell based approach est ce toujours aussi lent ?

je vois un truc comme ca:

présenté problématique et les 2 graphes

cause

csq (tests + explosion erreur +  non reproductibilité)

solutions ?

calculer indexs locaux pour toujours faire les ops dans le meme ordre.

- essai 1: cell based
--> pourquoi est ce plus lent ?

- essai 2: buffer de flux
*/
#import "@preview/fancy-units:0.1.1": qty

#show: body => {
  for elem in body.children {
    if elem.func() == math.equation and elem.block {
      let numbering = if "label" in elem.fields().keys() {
        n => {
          let h1 = counter(heading).get().first()
          numbering("(1.1)", h1, n)
        }
      } else { none }
      set math.equation(numbering: numbering)
      elem
    } else {
      elem
    }
  }
}

Real numbers are used in most scientific software. However, computers have finite memory to represent this infinite continuum. As a result, only a discrete subset can be stored, introducing round-off errors. The IEEE 754 @ieee754-2019 standard defines how floating point numbers are stored in hardware and specifies rounding rules for arithmetic operations. In particular, floating point operations must follow correct rounding, that is, the result of an operation should be the exact value, whether representable or not, rounded to the nearest machine number. One consequence is that addition is not associative, especially when combining numbers of different magnitudes. The following Python example shows this.
```python
(1e20 + (-1e20)) + 3.14 # outputs 3.14
1e20 + ((-1e20) + 3.14) # outputs 0.0
```
A consequence of this rounding behavior is that multiple executions of a parallel program can produce different results if the order of arithmetic operations depends on scheduling decisions. In our case, one of our unit tests simulates Watlab on an artificial circular dam break with sediment transport. It considers a domain $Omega = [0, 5] times [0, 5]$, with a circular subregion $Omega_D = { (x, y) in Omega | (x - 5/2)^2 + (y - 5/2)^2 <= (3/4)^2 }$ representing a dam that suddenly breaks. The mathematical initial state of the hydraulic variables for this test case is as follows:
$
  h^0 = cases(1 quad "if" (x,y) in Omega_D, 0 quad "if" (x,y) in Omega \\ Omega_D) wide h_s^0 = cases(0 quad "if" (x,y) in Omega_D, 1/5 quad "if" (x,y) in Omega \\ Omega_D)
$
with $h_s^n$ denoting the sediment level.
The difference in water height along the radial direction simulates a dam break over a few seconds. The parallel version described earlier fails this test. Moreover, the differences between the expected and actual results vary across executions. To better understand the issue, we recorded snapshots every
$#qty[0.25][[s]]$ and compared them with the serial version.
Results are shown in @fig_nondeterm.
We observe that the differences are nondeterministic.
In addition, both the proportion of diverging elements and
the maximum relative error tend to increase over time.

#import "@preview/subpar:0.2.2"
#subpar.grid(
  figure(box(image("../img/nnz_diff.svg"), clip:true, inset: (top:-10pt, bottom:-10pt, left: -10pt, right:-10pt), stroke: none), caption: [
    Evolution of diverging proportion
  ]), // <interf_based>,
  figure(box(image("../img/rel_diff.svg"), clip:true, inset: (top:-10pt, bottom:-10pt, left: -10pt, right:-10pt)), caption: [
    Evolution of maximum relative error
  ]),
  columns: (1fr, 1fr),
  caption: [Nondeterministic behavior of parallel implementation],
  label: <fig_nondeterm>,
  numbering: n => numbering("1.1", ..counter(heading.where(level: 1)).get(), n),
  numbering-sub-ref: (..n) => {
    numbering("1.1a", ..counter(heading.where(level: 1)).get(), ..n)
  },
  gap: 1.5em
)

// #subpar.grid(
//   figure(box(image("img/div_plot_1.5.svg", height: 35%), clip: true, inset: 0mm), caption: [
//     Diverging cells at #qty[1.5][s]
//   ]), // <interf_based>,
//   figure(image("img/div_plot_1.75.svg", height: 35%), caption: [
//     Diverging cells at #qty[1.75][s]
//   ]),
//   grid.cell(colspan: 2,
//   figure(image("img/div_plot_2.0.svg", height: 35%), caption: [
//     Diverging cells at #qty[2][s]
//   ])),
//   columns: 2, rows: 2,
//   caption: [Nondeterministic behavior of parallel implementation],
//   label: <tri_div>,
// )

The only source of nondeterminism in the program comes from scheduling decisions. After carefully verifying that no race conditions occur, we found that the execution order of threads affects the order of flux balancing in the interface-based approach, which can alter the result. For example, consider @memory_fluxes, and in particular the cell with index 3. In the serial version, interfaces are processed in order, so the accumulation in the buffer results in
$
  sum_(j) bold(T)^(-1)_j bold(F)_j L_j
  = bold(T)^(-1)_3 bold(F)_3 L_3
  + bold(T)^(-1)_6 bold(F)_6 L_6
  + bold(T)^(-1)_7 bold(F)_7 L_7
$
Whereas in parallel, interfaces are processed without any guaranteed order, so we have no control over the sequence in which the boundaries of cell 3 are handled, which might be
$
    &bold(T)^(-1)_3 bold(F)_3 L_3
  + bold(T)^(-1)_6 bold(F)_6 L_6
  + bold(T)^(-1)_7 bold(F)_7 L_7 \
  "or" wide
    &bold(T)^(-1)_3 bold(F)_3 L_3
  + bold(T)^(-1)_7 bold(F)_7 L_7
  + bold(T)^(-1)_6 bold(F)_6 L_6 \
  "or" wide
   &bold(T)^(-1)_7 bold(F)_7 L_7
  + bold(T)^(-1)_3 bold(F)_3 L_3
  + bold(T)^(-1)_6 bold(F)_6 L_6 \
  "or" wide &wide wide wide quad...
$
Due to round-off errors, all these operations, though mathematically equivalent, can produce different results in the computer implementation. Further investigation revealed an example of such discrepancies. The flux balance of a cell yielded in the first run was:
```cpp
(3.74744 - 4.61448) + 0.867004 = 9.70675e-18
```
While in the other:
```cpp
(0.867004 + 3.74744) - 4.61448 = 0
```
This is an example of _catastrophic cancellation_, a well-known round-off issue that causes significant precision loss when two close floating-point numbers cancel each other. Although the differences are relatively small, they propagate throughout the simulation due to the explicit nature of the computational scheme, which constantly reuses computed values, and to neighboring cells through the numerical fluxes. It is therefore not surprising to observe the patterns seen in @fig_nondeterm. Of course, these differences are merely numerical artifacts resulting from the computer-based discretization of the shallow water equations, which already introduce approximation errors. Thus, no execution can be considered physically more correct than another. However, the desire for reproducibility and the unbounded nature of error growth motivate us to adapt the parallel implementation to eliminate this nondeterministic behavior. The following sections present two attempts to achieve this goal.

Note that we did not observe such nondeterministic behavior in the Toce simulation case study, regardless of how long the simulation ran or how large the mesh was. The example highlighted in the circular dam break occurs because the cell appears to be in steady state: inflow and outflow cancel out. This does not seem to happen in the Toce simulation.

=== First attempt

To always get hydraulic values identical to the serial version, we just need to sum the fluxes in the same order, i.e. by increasing interface indices. This is not entirely trivial in the interface-based approach since a thread processing an interface cannot know if the previous ones have already been handled without expensive inter-thread communication. The simplest solution is to shift the summation to the finite-volume update step, adopting a cell-based approach. At this point, it suffices to retrieve the fluxes from the surrounding interfaces and accumulate their contributions in increasing order. As previously mentioned, the main caveat is the overhead from additional memory accesses.
Finally, note that this approach removes the need for mutexes.

=== Second attempt

A better approach that maintains performance while ensuring determinism is to transform each cell's buffer into a vector of buffers. Each interface has precomputed local left and right indices that point to the appropriate position in the buffer vector where the fluxes should be stored. In the update step, we simply accumulate the vector entries, avoiding any additional memory accesses outside the cell's buffer. Therefore, the number of uncached memory accesses is nearly the same as the interface-based implementation. \
However, one detail remains. Interfaces do not always add fluxes to the left and right cell buffers. When both water heights are below the user-defined threshold representing zero depth, the hydraulic variables are preserved but not added. The program handles this with if-else logic that checks the water levels in both cells. When shifting the flux balance to the cell update step, these conditions needed to be rechecked before accumulating the boundary interface fluxes in the first version. These checks require extra memory access and increase overhead. In this second version, we filled the buffer with +0 in these cases, since adding +0 leaves values unchanged in IEEE 754-compliant systems#footnote[More precisely, we have $x + (+0) = x$ for every floating point number $x$ except the negatively signed zero $-0$, for which $-0 + (+0) = +0$.].
