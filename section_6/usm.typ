#let unbold(it) = text(weight: "thin", it)

We now detail the data migration mechanisms that distinguish the GPU capable implementations from the previous ones. First, SYCL provides several APIs for managing memory. The _Unified Shared Memory_ (USM) model includes three allocation functions:

/ #unbold(`sycl::malloc_host`) : allocates memory in host memory. Unlike a standard C++ `malloc` call, the memory is pinned, meaning it cannot be paged out by the operating system and always resides in RAM. It is also accessible by the device. However, such access occurs remotely through PCIe queries, so no data migration is involved and the data stays in host memory.

/ #unbold(`sycl::malloc_device`) : allocates memory in device memory. It is not accessible by the host and requires explicit data copies to move data between host and device.

/ #unbold(`sycl::malloc_shared`) : allocates memory accessible by both host and device. Migrations are handled at runtime by the operating system and drivers using a page fault mechanism. As a result, performance depends on their quality and is backend dependent, as noted in @adaptivecpp_performance. According to @sycl_bench, this model is unstable on AMD backends and can cause random errors.

SYCL also includes the `sycl::buffer` and `sycl::accessor` model, which provides an abstract view of memory accessible by both host and device. These are implemented using USM under the hood. Data migrations are resolved at runtime based on encountered data dependencies, which increases kernel launch latency, as shown by @sycl_bench.

Based on these considerations, we excluded buffers and shared USM memory for handling data transfers. @sycl_bench shows that relying only on `malloc_host` is not viable because the data transfer time increases linearly with the number of device memory accesses to host memory. Instead, it is more efficient to load the data once at program initialization on the device and copy data back to the host only when needed, for example when output is required or to retrieve the minimum time step.

The remaining question is how to allocate memory on the host that must be sent to the device, as well as buffers that will receive cell arrays and reduced minimum values during execution. We can either use standard C++ heap allocations such as `new`, `malloc`, or `std::vector`, or rely on `malloc_host`. Again, @sycl_bench shows that non-pinned allocations are faster for host to device transfers if the number of copies is fewer than three. In our case, interface and cell arrays are transferred only once from CPU to GPU, so there is no need to use `malloc_host` for this data. This also allows us to use `std::vector`, which can be resized dynamically since the number of each interface type is unknown when parsing input files.

On the other hand, @sycl_bench demonstrates that using `malloc_host` for receiving buffers is preferable, as the CUDA driver cannot write directly to pageable memory and performs a temporary copy to pinned memory, adding overhead.
