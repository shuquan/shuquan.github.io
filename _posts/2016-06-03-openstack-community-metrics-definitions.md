---
layout: post
title: Metrics measured in each OpenStack program
description: "Some Metrics shown in OpenStack Community Activity Report is valuable."
modified: 2016-06-03
tags: [openstack]
---

## Metrics Definitions

### Metrics measured in each OpenStack program:

* Commit: this is defined as the action(s) that performes a change in the source code. Bots, merges and other type of automatic activity is removed from the records. In addition, when aggregating several git repositories, this metric only counts unique revisions (unique hashes found in the git repositories). Finally, all branches are aggregated to the analysis.
* Submitted changeset: a changeset is the process of peer reviewing source code changes. A commit is not merged to the master code of a given project till this is approved for at least one core reviewer of such project. A submitted changeset is defined as any changeset submitted to the Gerrit system. However, given the limitations of the current version of the tool, with at least 5,900 changesets detected as having an erroneous creation date, this metric counts the first patchset upload action.
* Merged and abandoned changsets: a merge is defined as the patchset that was finally submitted to the source code. An abandoned change- set is a potential merge that was finally dismissed by developers as being part of the source code. This status is found in the status of the final patchset. However, although a patchset can be merged or aban- doned, this action can be reverted. If a patchset presents several of these changes in the same period of time, only one of them is counted (the very last one). On the other hand, if those changes take place in different periods of analysis, both status would be counted.
* Open and closed ticket: a ticket in Launchpad is counted as closed if the status of such ticket is defined as ’Fix Released’. The rest of the tickets are counted as opened tickets.
* Active Core Reviewer: a core reviewer has the possibility to use +2 or -2 actions when reviewing the code. However, if there are developers that for some period do not use those actions, those can not be mea- sured as core reviewer. Thus, this metric provides information about ’active’ core reviewers. This can be also defined as those developers that actively have used the +2 or -2 review action. This metric is also filtered by branch of activity, only using ’master’. This helps to detect actual core reviewers in each of the projects.
* Authors: a developer is defined as author if she is the owner of the patchset sent for reviewing and this is merged into the source code. As previously indicated, automatic commits such bot’s are removed from this analysis.
* Efficiency closing issues: this metric is a derivation of the Backlog Management Index (BMI) that measures the number of closed tickets out of the opened tickets in a period of time. Values under 1.0 indicates that the number of closing issues is lower than the number of opened issues arriving. On the contrary, higher charts would indicate better maintenance effort by the community.
* Efficiency closing changesets: this metric is a derivation of the Backlog Management Index as it is named as Review efficiency index (REI). As similarly used in the BMI index, this metrics measures the number of closed changesets (merged or abandoned) out of the total number of new changesets.
* Time to Merge: this time consists of the time between the first upload of the first patchset (as defined as a submitted changeset) till the last patchset of the changeset is merged into the code and this is indicated in the comments side of the Gerrit tool. This metric is provided in number of days.
* Patchsets per changeset: this metric calculates the total number of iterations in a changeset till this is abandoned or merged.
* Time waiting for the reviewer or the submitter: a changeset is waiting for a reviewer action if a new patchset upload or a new changset arrives to the system. On the other hand, a submitter action is required when a specific negative verification or reviewing action takes place (Verified -1/-2 or Code-Review -1/-2). In addition, when a Code-Review +2 action takes place, it is assumed that the changset is closing and no more times are registered either for the reviewer or the submitter. For this analysis, those patchsets flagged as work in progress are ignored.

### Metrics measured in the general overview:

* Community structure, core, regular and casual developers: developers are ordered in descendant order by the number of commits authored for a given period. Core developers are defined as the list of developers that reach 80% of the total commits. Regular is the set of developers that are between that 80% and 95% of the commits. Casual develop- ers are found in the rest of the 5%. Bots are ignored in this list of developers.
* Developer per month: average of developers per month ignoring bots.
* Emails sent: number of emails sent by people to the several mailing
lists. Bots are not registered.
* People sending emails: number of people sending those emails ignoring bots.
* People initiating threads: a thread is defined as a list of emails that has the same root. There may exist threads of one email.
* Top threads: this list provides the longest threads in terms of number of emails that have a common root email.
* Questions, answers and comments in Askbot.
* People asking questions in Askbot: number of people sending a new question.
* Top visited questions.
* Top tags: each of the questions has a list of associated tags. The top tags are those with the highest number of repetitions aggregating all of the questions.
* Messages and people in IRC: this analysis ignores as a message those entries in the IRC channels that provide information about people entering or leaving the system.
