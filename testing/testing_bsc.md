To check whether the simulation on bsc simulator worked fine, we ran a testbench mbox/testbench/tb_int_multiplier.bsv from the mbox repository itself
<br>The code that was verified is mbox/baseline_multiplier/int_multiplier.bsv
<br>Commands used:
<br>Inside the shakti docker container
<br>root@5e75783d9c43:/home/shakti# bsc -u tb_int_multiplier_2.bsv
<br>root@5e75783d9c43:/home/shakti# bsc -u int_multiplier.bsv
<br>root@5e75783d9c43:/home/shakti# bsc -sim -e mk_tb_int_multiplier -o tb_int_multiplier_2_sim
  <br>  Bluesim object created: mk_tb_int_multiplier.{h,o}
  <br>  Bluesim object created: model_mk_tb_int_multiplier.{h,o}
  <br>  Simulation shared library created: tb_int_multiplier_2_sim.so
  <br>  Simulation executable created: tb_int_multiplier_2_sim
<br>root@5e75783d9c43:/home/shakti# ./tb_int_multiplier_2_sim
<img width="1268" height="760" alt="image" src="https://github.com/user-attachments/assets/dfa81e6d-1da0-42d5-8330-58265318a44c" />
Ran the test perfectly and verified the correctness of the multiplier module.
