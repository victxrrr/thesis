#import "@preview/fletcher:0.5.3" as fletcher: diagram, node, edge

#let light_blob(pos, label, w, tint: white, ..args) = node(
	pos, align(center, label),
	width: w,
	fill: tint.lighten(90%),
	stroke: 1pt + tint.lighten(30%),
	corner-radius: 5pt,
	..args,
)

#let blob(pos, label, w: auto, tint: white, ..args) = node(
	pos, align(center, label),
	width: w,
	fill: tint.lighten(70%),
	stroke: 1pt + tint.darken(20%),
	corner-radius: 5pt,
	..args,
)

#let scale_width(canvas) = {
  context {
    let canvas-size = measure(canvas)
    layout(size => {
      let width = canvas-size.width
      let width = size.width
      scale(width/canvas-size.width * 100%, canvas)
    })  
  }
}

When implementing @hydroflow_gpu, the main challenge was handling polymorphism. In programming, polymorphism refers to the ability of objects to share a common interface while having different behavior depending on their type. Watlab's architecture relies heavily on this concept. For example, the solver includes several types of boundary conditions and therefore various types of interfaces. In the code, we define a base class `GenericInterface` that includes functions expected in every interface, typically a `Flux` method to compute hydraulic transfers and some helper functions used to calculate physical quantities common to all numerical schemes. Each derived class inherits from `GenericInterface`, overrides the `Flux` method, and still uses the other functions from the base class. When computing fluxes, we can call the `Flux` method on each interface directly, taking advantage of runtime polymorphism. A diagram showing interface polymorphism is provided in @polymorph. The `Flux` function is declared as virtual, meaning it is not implemented in the base class and must be defined in the derived classes, while all derived classes can access the helper function `Sigma`.


#figure(placement: auto, scale(85%, diagram(
	spacing: 8pt,
	cell-size: (8mm, 10mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
  debug: 0,

  let dx = 100mm,
  let dy = -16mm,
  let i = 100%/10,

  let style = (stroke: (dash: "dashed", )),

  blob((0mm, -.5mm), [
    *GenericInterface* #v(-.5em)
    ```cpp 
virtual void Flux();
double Sigma(...);
```]
  , name: <base>),
  blob((dx, -5*dy), [*HydroBCDischarge* #v(-.5em)
```cpp 
void Flux();
```], name: <der1>),
edge((<base.north-east>, 0%, <base.south-east>), <der1.west>, ..style, label: [_inheritance_]),
blob((dx, -4*dy), [*HydroBCHydrograph* #v(-.5em)
  ```cpp 
void Flux();
```], name: <der2>),
edge((<base.north-east>, 1*i, <base.south-east>), <der2.west>, ..style),
blob((dx, -3*dy), [*HydroBCLimnigraph* #v(-.5em)
  ```cpp 
void Flux();
```], name: <der3>),
edge((<base.north-east>, 2*i, <base.south-east>), <der3.west>, ..style),
blob((dx, -2*dy), [*HydroBCTransmissive* #v(-.5em)
  ```cpp 
void Flux();
```], name: <der4>),
edge((<base.north-east>, 3*i, <base.south-east>), <der4.west>, ..style),
blob((dx, -1*dy), [*HydroBCWall* #v(-.5em)
  ```cpp 
void Flux();
```], name: <der5>),
edge((<base.north-east>, 4*i, <base.south-east>), <der5.west>, ..style),
blob((dx, 0*dy), [*HydroBCWaterLevel* #v(-.5em)
  ```cpp 
void Flux();
```], name: <der6>),
edge((<base.north-east>, 5*i, <base.south-east>), <der6.west>, ..style),
blob((dx, 1*dy), [*HydroFluxLHLLC* #v(-.5em)
  ```cpp 
void Flux();
```], name: <der7>),
edge((<base.north-east>, 6*i, <base.south-east>), <der7.west>, ..style),
blob((dx, 2*dy), [*SedBCDischarge* #v(-.5em)
  ```cpp 
void Flux();
```], name: <der8>),
edge((<base.north-east>, 7*i, <base.south-east>), <der8.west>, ..style),
blob((dx, 3*dy), [*SedBCTransmissive* #v(-.5em)
  ```cpp 
void Flux();
```], name: <der9>),
edge((<base.north-east>, 8*i, <base.south-east>), <der9.west>, ..style),
blob((dx, 4*dy), [*SedBCWall* #v(-.5em)
  ```cpp 
void Flux();
```], name: <der10>),
edge((<base.north-east>, 9*i, <base.south-east>), <der10.west>, ..style),
blob((dx, 5*dy), [*SedFluxCLHLLC* #v(-.5em)
  ```cpp 
void Flux();
```], name: <der11>),
edge((<base.north-east>, 10*i, <base.south-east>), <der11.west>, ..style),

)),
caption: [An example of polymorphism used in Watlab])<polymorph>

To ensure that the correct version of the `Flux` virtual method is called based on the type, C++ uses virtual method tables (vtables) and virtual table pointers (vpointers). At the class level, a vtable is created containing function pointers for each virtual function the class implements. This table is shared by all instances of the class. Each instance includes a hidden member, the vpointer, which is set at construction to point to the correct vtable. When a virtual function is called, the vpointer is dereferenced and the vtable it points to is indexed to execute the appropriate overriding function.

In typical GPU-enabled code, data is first initialized in host memory and then copied to device memory. This copy includes all class members and may duplicate member functions to generate code for execution on the device. However, the vpointer is also copied, and it may point to a vtable that resides in host memory. At runtime, this causes an illegal memory access when the device attempts to use a function pointer located in host memory. For this reason, virtual functions are not supported in the SYCL 2020 standard.

The Kokkos documentation @kokkosDoc, on the other hand, discourages the use of virtual functions but provides a workaround. This workaround is not portable across all backends and is suboptimal in terms of performance. In a nutshell, it relies on the placement new technique, which allows using the new operator to construct an object in a preallocated memory buffer. In this case, the buffer is allocated in the device memory, and the object instantiation is performed within kernels. Since objects are instantiated on the device, their vtables point to device code rather than host code. More information about the exact pseudocode can be found in the Kokkos documentation. This technique results in unproductive and hard to read code. We tried it using AdaptiveCpp, but it led to memory corruption errors related to alignment issues. For these reasons, this solution is not viable in the long term for Watlab development.

A simpler way to handle virtual functions is to remove them entirely. To do so, we reworked the Watlab source code to eliminate runtime polymorphism. This led to highly redundant code. For instance, instead of having a single array of `GenericInterface` pointers on which we can directly call the Flux method, we now have separate arrays for `HydroFluxLHLLC` interfaces, `HydroBCWall` interfaces, `HydroBCTransmissive` interfaces, and so on. These arrays must be processed one after the other during flux computations. Separate memory allocations in the GPU memory are also required. Therefore, if someone wants to implement a new type of interface boundary, the code must be carefully adapted.

Polymorphism is also used in Watlab when sediment transport is considered. As shown in @polymorph, each interface type is adapted for this case and has an equivalent class prefixed by Sed that also derives from the GenericInterface class. The cell programming implementations also differ. We have a base class, `ComputationalCell`, with two derived subclasses, `CellSWE` and `CellSWE_Exner`, to distinguish between the two cases, as the numerical schemes and the number of hydraulic variables differ. In the original implementation, they were referenced through base class pointers, allowing for uniform handling in most cases. With the removal of polymorphism, additional if-else logic is needed to handle the different cases, which further reduces modularity.

However, this GPU implementation provides a clear way to analyze in depth the performance gains from a GPU port. It helps assess whether a full refactoring of the code architecture to eliminate runtime polymorphism and improve GPU compatibility is truly worthwhile.
