.. _slurm_guide:

Slurm Queueing System Guide
###########################

Basic Slurm Terminology
=======================

.. toctree::
   :maxdepth: 3

   terminology


Job Types and Job Submission
============================

.. toctree::
   :maxdepth: 3

   interactive_jobs
   batch_jobs
   job_dependencies

Job Environment
===============

.. toctree::
   :maxdepth: 3

   job_environment


Strategies When Submitting Slurm Jobs
======================================

Due to LARCC's resource policies (see :ref:`Resource restrictions <resource_restrictions>`), users are limited to:

- 20 concurrent job submissions.
- 2 nodes maximum per user.

Depending on your resource requests, multiple jobs may run on the same node, but the 20-job submission limit must always be respected. To
maximize resource utilization while complying with these restrictions, there are multiple strategies you can follow. This section explains
the most common ones.

.. toctree::
   :maxdepth: 3

   job_submission_strategies

