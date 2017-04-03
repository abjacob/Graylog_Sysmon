# Graylog_Sysmon
Advanced configuration for Graylog w/Sysmon

I'll be adding more documentation to this as time permits ;)

Ransomware Detection from:
https://fsrm.experiant.ca/

## Pipeline Order ##

### Stage 1 ###
~~~~
sysmon cleanup (gl2_source_fix)
sysmon cleanup
~~~~

### Stage 2 ###
~~~~
sysmon threatintel
detect ransomware
threat indicators
network threat indicators
add file_created field
~~~~

### Stage 3 ###
~~~~
sysmon threatintel inflate
~~~~

Set Message Processor Configuration to the following order:

Message Filter Chain

Pipeline

GeIP Resolver