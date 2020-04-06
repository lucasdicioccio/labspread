
% attribution model
int: nLab;
int: nZone;
int: nTime;
int: sample_lifetime;

set of int: LAB = 1..nLab;
set of int: ZONE = 1..nZone;
set of int: TIME = 1..nTime;
set of int: DELAY = 0..sample_lifetime;

% demand of samples produced by zones
array[ZONE,TIME] of int: demand;
% capacity of labs to process samples, may vary with time to model things like week-ends
array[LAB,TIME] of int: capacity;
% transit represents a delay from one zone to some lab
array[ZONE,LAB] of int: transit;

% decisions about routing samples: dispatching and dropping samples
int: maxAttr = sum(z in ZONE, t in TIME)(demand[z,t]);
array[ZONE,LAB,TIME,DELAY] of var 0..maxAttr: dispatch;
array[ZONE,TIME] of var 0..maxAttr: dropped;

% helper: work sent from zone to a lab at a given time (whichever delay is dispatched)
array[ZONE,LAB,TIME] of var 0..maxAttr: sent;
constraint forall(l in LAB, z in ZONE, t in TIME)
  (sent[z,l,t] = sum(d in DELAY)(dispatch[z,l,t,d]));

% helper: workload processed by a lab at a given time (includes delayed dispatches)
array[LAB,TIME] of var int: load;
constraint forall(l in LAB, t_load in TIME)
 ( load[l,t_load] = sum(t_route in t_load-sample_lifetime..t_load where t_route > 0, z in ZONE)
                       (dispatch[z,l,t_route,t_load-t_route])
 );

% cannot delay (including transit time) past sample_lifetime
constraint forall(z in ZONE, l in LAB, t in TIME, d in DELAY)
  ( (transit[z,l] + d > sample_lifetime) -> dispatch[z,l,t,d] = 0);

% must dispatch all demand
constraint forall(z in ZONE, t in TIME)
  (demand[z,t] - dropped[z,t] = sum(l in LAB, d in DELAY)( dispatch[z,l,t,d] ));

% cannot overload labs
constraint forall(l in LAB, t in TIME)
  (capacity[l,t] >= load[l,t]);

% minimize dropped amounts
var int: total_drop = sum(array1d(dropped));

solve minimize total_drop;

output [ "t=\(t)\n"
       ++ "  demand=\(sum(z in ZONE)(demand[z,t]))\n"
       ++ "  capacity=\(sum(l in LAB)(capacity[l,t]))\n"
       ++ "  drop=\(sum(z in ZONE)(dropped[z,t]))\n"
    %   ++ "  sent=" ++ concat([ "(\(z)->\(l),\(sent[z,l,t])) " | z in ZONE, l in LAB ]) ++ "\n"
    %   ++ "  load=" ++ concat([ "(\(l),\(load[l,t]))" | l in LAB]) ++ "\n"
       ++ "\n"
       | t in TIME
       ] ++
       [ "total_drop = \(total_drop)"
       ];