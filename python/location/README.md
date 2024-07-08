# Facility Location with Regions

## Overview

These notebooks solve a facility location problem with regions using five different approaches of hooking up SAS Optimization to Python. It also includes examples of using DECOMP.

### Installation

All the examples need to connect to either SAS 9.4 using saspy or SAS Viya using swat.

See the [saspy documentation](https://sassoftware.github.io/saspy/configuration.html#sascfg-personal-py) for instruction on how to connect to SAS 9.4 using saspy.

See the [swat documentation](https://sassoftware.github.io/python-swat/getting-started.html) for instructions on how to connect to SAS Viya using swat. The SAS Viya connection information can be stored in a file cas.py that contains information similar to this one:

```
cas_options = {
    "hostname": "http://mycasserver",
    "pkce": True
}
```

