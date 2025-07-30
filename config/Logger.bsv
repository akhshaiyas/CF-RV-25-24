`ifdef simulate
  `ifdef static_check
    `define logLevel (modname, level, log_string) \
        begin \
            if (`VERBOSITY > level) $display($time, " ", log_string); \
        end

    `define logTimeLevel (modname, level, log_string) \
        begin \
            let ____t <- $time; \
            if ((`VERBOSITY > level) || ((_t >= `LOG_START) && (_t < `LOG_END))) $display($time, " ", log_string); \
        end
  `else
    `define logLevel (modname, level, log_string) \
        begin \
            let display_all <- $test$plusargs("fullverbose"); \
            let current_module <- $test$plusargs("mmodname"); \
            let current_level <- $test$plusargs("llevel"); \
                  let ____t <- $time; \
            if( display_all || (current_module && current_level)) $display($format("[%10d", ____t) + $format("] ") + log_string); \
        end

    `define logTimeLevel (modname, level, log_string) \
        begin \
            let display_all <- $test$plusargs("fullverbose"); \
            let current_module <- $test$plusargs("mmodname"); \
            let current_level <- $test$plusargs("llevel"); \
                  let ____t <- $time; \
            if (display_all || (current_module && current_level) || ((_t >= `LOG_START) && (_t < `LOG_END))) $display($format("[%10d", ____t) + $format("] ") + log_string); \
        end
  `endif
`else
  `define logLevel (modname, level, log_string) begin end
  `define logTimeLevel (modname, level, log_string) begin end
`endif
