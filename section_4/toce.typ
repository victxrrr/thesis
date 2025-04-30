In @Testa2007, the authors described flash flood experiments conducted on a 1:100 scale physical model of the Toce River valley, built in concrete. An urban district made of several concrete block buildings was placed in the riverbed to simulate flooding in a populated area and study the complex flow patterns caused by water interactions. Multiple water depth gauges were installed to collect bathymetric data, and an electric pump controlled the inflow discharge, determining the flood intensity. Together, the topography, inflow, and gauge measurements form a dataset well-suited for validating mathematical flood models.

In our case, we use a mesh file based on this experimental setup, shown in @Toce. 
The inflow enters the domain through the west boundary indicated in the figure and exits through 
a transmissive boundary at the far end. Note the 20 aligned squares representing scaled models of buildings. Sediment transport is not considered in this case study.

#figure(
    box(image("../img/toce.svg"), clip: true, inset: (top: -30pt)),
    caption: [Mesh corresponding to the small-scale model of the Toce River]
)<Toce>

The key properties of the mesh geometry are listed in @meshes. 
Regarding simulation parameters, the CFL number is set to $sigma = 0.9$, and the simulation runs from time 7 to 60. This choice is based on the boundary hydrograph provided with the dataset (@inflow). We also periodically generate images of the hydraulic variables and gauge measurements, with gauge positions matching those in @Testa2007 as described in @simulations.

#figure(
    box(image("../img/inflow.svg", width: 70%), clip: true, inset: (top: 0pt)),
    caption: [Inflow hydrograph]
)<inflow>




