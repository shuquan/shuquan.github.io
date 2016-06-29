---
layout: post
title: "Monitoring Guide"
description: "Link to a mirantis blog about monitoring."
tags: [openstack, ceilometer]
comments: true
link: https://docs.mirantis.com/openstack/fuel/fuel-7.0/monitoring-guide.html  
---

### Monitoring Domains

* Availability Monitoring
* Performance Monitoring
* Resource Usage Monitoring
* Alerting
  * Healthy - when both the HA functions of the controller cluster are still being ensured and no critical errors are being reported by the monitoring system for a service.
  * Degraded - when one or more critical errors are reported by the monitoring system for a service but the HA functions of the controller cluster are still being ensured.
  * Failed - when both the HA functions of the controller cluster are not being ensured anymore and one or more critical errors are being reported by the monitoring system for a service.

### Monitoring Activities

* Services, Processes and Clusters Checks
* Metering
* Logs Processing
* Logs Indexing
* OpenStack Notifications Processing
* **Diagnosing** versus Alerting. I think people normally will ignore Diagnosing and put lots of effort on Alerting.
* Time Synchronization

### Hardware and System Monitoring

* IPMI
  * Components temperature
  * Fan rotation
  * Components voltage
  * Power supply status (redundancy check)
  * Power status (on or off)
* Disks Monitoring (rely on the S.M.A.R.T interface)
* Host Monitoring
* Disk Usage Monitoring
* Soft RAID Monitoring
* Filesystem Usage Monitoring
* CPU Usage Monitoring
* RAM Usage Monitoring
* Swap Usage Monitoring
* Process Statistics Monitoring
* Network Interface Card (NIC) Monitoring
* Firewall (iptables) Monitoring

### Virtual Machine Monitoring

* Block IO
  * read_reqs
  * read_bytes
  * write_reqs
  * write_bytes
* Network IO
  * rx_bytes
  * rx_packets
  * rx_errors
  * rx_drops
  * tx_bytes
  * tx_packets
  * tx_errors
  * tx_drops
* CPU
  * cputime
  * vcputime
  * systemtime
  * usertime
* VM Network Traffic (sFlow)
