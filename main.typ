#import "@preview/glossarium:0.5.2": make-glossary, register-glossary, print-glossary, gls, glspl

#counter(page).update(n => n + 0)

#set text(11pt, lang: "en")
#set align(left)
//#set page(numbering: "— 1 —")
#set page(numbering: "1")
#set heading(numbering: "1.1.1")
#set par(
  first-line-indent: 1em,
  justify: true,
)
#set figure.caption(separator: " - ")
#set figure(gap: 5mm)
//#set math.equation(numbering: it => emph[#numbering("(i)", it)])
// #let numbered_eq(content) = math.equation(
//     block: true,
//     numbering: it => emph[#numbering("(i)", it)],
//     content,
// )

//#set figure(numbering: it => emph[#numbering("(i)", it)])

#set math.equation(numbering: "(1)")

#import "@preview/fancy-units:0.1.1": unit

#set math.vec(delim: "[")
#set math.mat(delim: "[")

#outline()
#pagebreak()
#outline(title: "Figures", target: figure.where(kind: image))

#pagebreak()

#show: make-glossary
#let entry-list = (
  (
    key: "kuleuven",
    short: "KU Leuven",
    long: "Katholieke Universiteit Leuven",
    description: "A university in Belgium.",
  ),
  // Add more terms
)
#register-glossary(entry-list)

= Introduction

hook 
problématique 
exemple parlant de pq on doit accelerer

#pagebreak()
= Governing equations
== Shallow water equations

#include "SWE.typ"

== Numerical scheme

#include "FV.typ"

== Data parallelism

#include "data_parallelism.typ"

== Program structure

#include "program_struct.typ"

#pagebreak()
= State of the art

== Parallelization methods

#include "parallel_methods.typ"

== Graphics Processing Units

#include "state_gpu.typ"

== The zoo of GPGPU languages

#include "zoo.typ"

== Trends in SWE solvers

#include "trends_swe.typ"

#pagebreak()
= Case studies

== Toce

== Theux

== Profiling

#pagebreak()
= Implementations
== CPU

=== What I did first ?

// parler de ce que j'ai fait les premiers mois ?

=== Going parallel

#include "parallel_cpu.typ"

=== The precision issue

#include "nondeterm.typ"

=== Memory

#include "memory_cpu.typ"

== Case studies results

#include "cpu_case_studies.typ"

== GPU
=== Hardware
=== Weaknesses & strengths
==== Memory latencies
==== Occupancy

=== Proof of Concept

#include "poc.typ"

==== Results

#include "poc_results.typ"

=== Optimizations
==== RCM
==== Edge reordering

#include "edge_reordering.typ"


==== SoA ?
==== Streams boundary / inner edges
=== Case studies results

#pagebreak()
= Perspectives

#pagebreak()
= Conclusion

#pagebreak()
= Acknowledgements

#print-glossary(
 entry-list
)

#pagebreak()
#bibliography("ref.bib", full:false)
