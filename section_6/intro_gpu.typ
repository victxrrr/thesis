As introduced in the state of the art, Graphics Processing Units were originally used for video rendering. Historically, their main users were in the gaming community. In most video games, a dynamic virtual world must be rendered many times per second to ensure a smooth visual experience. This process involves computing the color of each pixel based on lighting, textures, and perspective. The massively parallel architecture of GPUs is well suited for this task.

#figure(
  box(
    image("../img/drawing.svg", width: 75%),
    clip: true,
    inset: (bottom: -12.5mm, top: -3mm))
    ,
  caption: [Insight behind Watlab's GPU implementation ]
) <drawing>

We observe a clear parallel with our hydraulic solver: pixels are replaced by interfaces and cells, and the small, repeated computations become the calculation of fluxes, source terms, and finite-volume updates (@drawing). This intuition has driven research into using GPUs to accelerate SWE solvers and, more broadly, scientific simulations for over a decade. As reported in @TableSpeedups, many GPU implementations have achieved impressive speedups that are not attainable on CPUs due to their limited core count. It is therefore natural to want Watlab to benefit from this technology as well.

Reviewing the literature revealed that a key to efficient implementation on Graphics Processing Units is a solid understanding of their underlying architecture. We will therefore first present the hardware, followed by the programming abstraction built on top of it.