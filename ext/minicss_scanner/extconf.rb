# frozen_string_literal: true

require "mkmf"

# Require Ruby >= 3.2 for rb_str_export_to_enc availability
have_func("rb_str_export_to_enc")
create_makefile("minicss_scanner")
