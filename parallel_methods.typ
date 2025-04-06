Modern Central Processing Units (CPUs) contain multiple processing cores, which are independent units that execute streams of instructions. Supercomputers, on the other hand, are machines with many CPUs that can work together on the same problem. Both types of parallel architectures rely on parallelism—the ability to break a computational task into smaller parts that can be executed independently and simultaneously. Because it occurs at multiple levels, parallelism is difficult to define precisely.

To review the current parallelization methods, we will consider the more general abstraction of a parallel computer, which can be thought of as an architecture with multiple processors that allow multiple instruction sequences to be executed simultaneously. As the processors work together to solve a common problem, they need to access a common pool of data. \
Parallel machines differ in how they tackle the problem of reconciling multiple memory accesses from multiple processors. According to the _distributed memory_ paradigm, each processor has its own address space, and no conflicting shared accesses can arise. In the _shared memory_ paradigm, all processors access a common address space. The existing programming models for taking advantage of parallel processors follow one of these paradigms, each of which involves a different set of constraints and capabilities.

Note that this section and the following are primarily based on the work of @Eijkhout.

=== Threads
The building block of a parallel programming model implementing the shared memory paradigm is the thread. A thread is an execution context—that is, a set of register values that enables the CPU to execute a sequence of instructions. Each thread has its own stack for storing local variables and function calls, but it shares the heap of the parent process (i.e., an instance of a program) with other threads, and therefore shares global variables as well. \
It is the operating system, through its scheduler, that decides which thread is executed, when, and on which processor. These scheduling decisions are often made at runtime and may vary from one execution to another @lee2016introduction. Therefore, if shared data is accessed concurrently by different threads, the final result may depend on which thread executes first—this is known as a race condition. To solve this problem, inter-thread synchronization is needed, typically through mechanisms such as locks, which allow only one thread to access a shared resource at a time while others wait. \
Finally, threads are dynamic in the sense that they can be created during program execution.

C++ provides native support for threads and locks through the <thread> and <mutex> libraries. The pseudocode below demonstrates an example of thread spawning. The instructions to perform take the form of function.
```cpp 
void writeOutput(arg){ ... }              // job to do

std::thread myThread(writeOutput, args);  // launch
myThread.join();                          // wait for thread to finish
```

=== OpenMP

OpenMP @openmp is a directive-based API and the most widely used shared memory programming model in scientific codes. It is built on threads, inheriting related paradigms, and hides thread spawning and joining from the developer through compiler directives that automatically generate parallel code. For example, a `for` loop can be parallelized as follows:
```cpp 
#pragma omp parallel for                  // compiler directive
for (int i = 0; i < nCells; i++) {
  ...
}
```
OpenMP is designed to be easy to deploy and supports incremental parallelization. Since it primarily aims to distribute loop iterations across parallel processors, it is suited for data parallelism, where the same independent operations must be performed on different pieces of data.

=== MPI

MPI (Message Passing Interface) @MPI-standard is the standard solution for implementing distributed memory parallel programming. This library interface enables both data and task parallelism, i.e., executing subprograms in parallel. In this paradigm, MPI processes cannot access each other's data directly, as memory is distributed either virtually or physically. Therefore, processes must perform communication operations—one-sided, point-to-point, or collective—to exchange data.

The distributed memory model also requires an initial partitioning of data, such as the mesh in shallow water equation (SWE) solvers. In such cases, authors often rely on external libraries like METIS @metis to partition the domain in a way that minimizes inter-process communication. Although MPI can be used on a single multiprocessor system, it truly demonstrates its power when deployed across a cluster of CPU nodes.



