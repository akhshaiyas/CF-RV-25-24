# Commands: 
<br> bsc -u int_multiplier_pipelined_5stages.bsv
<br> bsc -u tb_new_5stage.bsv
<br> bsc -u mk_tb_int_multiplier.bsv
<br> bsc -sim -e mk_tb_int_multiplier -o tb_int_multiplier_5stage_sim
<br> ./tb_int_multiplier_5stage_sim

<br> Multiplier module: https://gitlab.com/shaktiproject/cores/mbox/-/blob/master/pipelined_multiplier/int_multiplier_pipelined_5stages.bsv?ref_type=heads
<br> mk_tb_int_multiplier.bsv - 

package mk_tb_int_multiplier;

import tb_new_5stage :: *;

(* synthesize *)
module mk_tb_int_multiplier();
    mk_tb_int_multiplier_pipelined_5stages();
endmodule

endpackage

![WhatsApp Image 2025-07-19 at 17 46 17_47fd8449](https://github.com/user-attachments/assets/dbcd05ca-1a9c-4fd5-a6ff-4e35470beb3a)
