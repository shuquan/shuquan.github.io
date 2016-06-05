---
layout: post
title: "OpenStack Ceilometer, cloud performance, and hardware requirements"
description: "Link to a mirantis blog about ceilometer benchmark."
tags: [openstack, ceilometer]
comments: true
link: https://www.mirantis.com/blog/openstack-ceilometer-cloud-performance-hardware-requirements  
---

### Performance testing results summary

We performed Ceilometer benchmark tests and collected results primarily in the 20-node lab configuration. As expected, we found that the main load on the cloud (i.e., on the nodes running Ceilometer, MongoDB, and related controllers) resulted from **polling**. Our goal was to determine some guidelines for setting the polling interval to provide the greatest information granularity possible without imperiling overall system performance.

Polling load (and on average, all Ceilometer load on the cloud) actually depends on two factors:

    * Number of resources from which metrics are collected. In our benchmark testing, we used VMs as units of measurement, and we tried 360, 1000, and 2000 VMs.

    * Polling interval. Generally speaking, the smaller the polling interval is, the bigger the load.

Together, these imply that for the purposes of our benchmark tests, we could use minimally configured VMs, since in this case, any given VM served merely as a unit for information collection. The VMs we created and polled were set up as single CPU systems, each having 128MB of RAM.

### Results and recommendations

This section summarizes some significant results and recommendations. (See the section Lab configurations, testing processes, and data collected for specifics of the data collected.)

Tests results showed that 2000 VMs with a 1-minute polling period load is permissible for Ceilometer configured with MongoDB.

It’s important to note two key points. First, the IO load in this case was too heavy for running MongoDB instances on the cloud controllers (as we did). The MongoDB IOStat util indicated a peak load of close to 100%. The second point is that many data samples are written to the database and after only one day running, the MongoDB cluster held 170 GB per device.

To avoid this problem, we recommend that you if you use **2000 VMs with a 1-minute polling interval** (or a configuration with a similar or greater load), use separate nodes for instances of MongoDB processes running together as a replica set.

If you are using **1000 VMs, with 1-minute polling**, there is a lighter IO load. In this case, MongoDB isn’t blocking other IO operations and it works correctly with other services.
