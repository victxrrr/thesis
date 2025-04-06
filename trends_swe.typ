Various implementations of SWE solvers exist. To accelerate their codes, hydraulic researchers initially focused on CPU parallelization. Some implementations decompose the computational domain into smaller regions and use MPI to solve subproblems simultaneously @DELIS2009 @RAO2004 @CASTRO2006 @HERVOUET2000 @PAU2006 @WRIGHT2006 @Sanders @LACASTA2013225.  The main argument for using the
paradigm is the ability to deal with gigantic domains consisting of many cells and interfaces that could not be stored on a single node due to the limited amount of memory available. Others still adopted a shared memory model with OpenMP @NEAL2009 @ZHANG2014126 which allows to get rid of any inter-process communication. However, since the achievable speed-up with these methods is limited by the number of processor cores, interest grew in leveraging GPUs for solving SWE equations even before the advent of GPGPU languages like CUDA. For example, Lamb et al. @LAMB2009 used Microsoft DirectX 9 @MicrosoftDX9, while @NEAL2010 employed ClearSpeed @ClearSpeed2007 accelerator cards, a now-defunct manufacturer. Other implementations @HAGEN2005 @LASTRA2009 @LIANG2009 rely on Cg @Cg and OpenGL @OpenGL, the graphical predecessor of OpenCL. Although these GPU implementations achieved significant speedups, the graphical nature of their implementation language made them difficult to understand and maintain. Therefore, the release of CUDA motivated many authors @CASTRO2011 @Brodtkorb2010 @dlA2011 @KALYANAPU2011 @DELAASUNCION2013441 @VACONDIO201460 @LACASTA20141 @Petaccia2016 @CARLOTTO2021105205 @Herdman to deploy their SWE solvers on GPUs because of the reduced development effort. Meanwhile, others @SMITH2013334 @Herdman chose OpenCL to improve the portability of their GPU implementation. Finally, OpenACC implementations @ZHANG @LIU @Herdman @Hu2018 were also explored, motivated by the minimal recoding effort.

With the growing use of GPU-accelerated hydrocodes, the next step was to leverage multiple GPUs @Saetra2010 by decomposing the domain for further speedup. This multi-GPU approach, implemented with CUDA+MPI @MORALESHERNANDEZ2021105034 or OpenACC+MPI @SALEEM2024106141, achieved low run times but showed limited scalability with a large number of GPUs due to bottlenecks on communication and I/O tasks. Besides, given the growing hardware heterogeneity in HPC infrastructures, Caviedes-Voullième et al. @SERGHEI developed a high-performance, portable shallow-water solver with multi-CPU and multi-GPU support using Kokkos. Similarly, Büttner et al. @sycl_swe compared GPU and FPGA performance for a shallow-water solver using the finite element method with SYCL.

All the presented methods benefit from different acceleration factors compared to the serial version of the code, depending on the numerical scheme, case study, implementation details, profiling protocol, and hardware used. As a result, their performance may not directly reflect what we can expect for Watlab.
To provide better insights, we present in @TableSpeedups an overview of the speedups achieved with different parallel technologies, along with relevant hardware and test case contexts. Given the broad range of cited articles, this comparative table includes a non-exhaustive selection of studies chosen for relevance. Priority is given to recent implementations that either:

- Use a numerical scheme similar to Watlab,
- Serve as representative examples of a given parallel technology, or
- Feature novel optimizations or programming approaches.

#show table.cell.where(y: 0): strong
#set table(
  stroke: (x, y) => if y == 0 {
    (bottom: 0.7pt + black)
  },
  align: (x, y) => (
    if x == 66 { right }
    else if x == -1 { left + horizon }
    else {center + horizon}
  )
)

#set text(
  size:10pt
)

#figure(
    placement: auto,
table(
  gutter: 1pt, 
  columns: (15%, 12%, 19%, 12%, 11%, 12%, 19%),
  table.header(
    [Reference],
    [API],
    [Hardware],
    [Scheme],
    [Mesh],
    [Cells],
    [Max. speedup]
  ),
  [ParBreZo @Sanders], [MPI], [Intel Xeon E5472], [Roe], [Unstruct.], [374 414 \ Dry/Wet], [*27$times$/48 cores*],
  table.hline(stroke: .5pt),
  
  [Petaccia et al. @Petaccia2016], [OpenMP], [Intel i7 3.4 GHz], [Roe], [Unstruct.], [200 000 \ Dry/Wet], [*2.35$times$/4 cores*],
  table.hline(stroke: .5pt),

  [Castro et al. @CASTRO2011], [CUDA], [NVIDIA GTX 480], [Roe], [Unstruct.], [1 001 898 \ Wet], [*152$times$/480 cores* \ (single precision) \ *41$times$/480 cores* \ (double precision)],
  table.hline(stroke: .5pt),

  [G-Flood @VACONDIO201460], [CUDA], [NVIDIA GTX 580], [HLLC], [Struct.], [3 141 592 \ Dry/Wet], [*74$times$/512 cores* \ (single precision)],
  table.hline(stroke: .5pt),

  [Lacasta et al. @LACASTA20141], [CUDA], [NVIDIA Tesla C2070], [Roe], [Unstruct.], [400 000 \ Dry/Wet], [*59$times$/448 cores* \ (double precision)],
  table.hline(stroke: .5pt),

  [Liu et al. @LIU], [OpenACC], [NVIDIA Kepler GK110], [MUSCL-Hancock + HLLC], [Unstruct.], [2 868 736 \ Dry/Wet], [*31$times$/2496 cores*],
  table.hline(stroke: .5pt),

  [TRITON @MORALESHERNANDEZ2021105034], [CUDA + MPI], [386 NVIDIA Volta V100], [Augmented Roe], [Struct.], [68 000 000 \ Dry/Wet],  [*$<=$43176$times$/1966080 cores* #footnote[The parallel speedup over serial time is not measured in this paper; instead, it is computed relative to a CPU multithreaded implementation. The presented speedup factor is an estimate, assuming the multithreaded implementation achieves perfect speedup with respect to the available cores.]],
  table.hline(stroke: .5pt),

  [Saleem and Norman @SALEEM2024106141], [OpenACC + MPI], [8 NVIDIA Volta V100], [MUSCL + HLLC], [Unstruct.], [2 062 372 \ Dry/Wet], [*$<=$1989$times$/40960 cores*],
  table.hline(stroke: .5pt),

  [SERGHEI @SERGHEI], [Kokkos], [NVIDIA RTX 3070], [Roe], [Struct.], [515 262 \ Dry/Wet], [*51$times$/5888 cores*],
  table.hline(stroke: .5pt),
),
caption: [
  An overview of the most significant reported speedups compared to serial implementations is provided. All hydrocodes use an explicit finite volume method, though the flux computation and reconstruction schemes may differ (as noted in the fourth column). We focused on test cases involving wet and dry cells, which present a worst-case scenario for GPU acceleration due to thread divergence (see Section REF). These case studies include analytical circular dam breaks, realistic dam breaks, and flood simulations. We believe these are the primary applications of the Watlab program and are likely to be run at large scales, requiring significant execution times, making them the most relevant for focus.
]
)<TableSpeedups>


