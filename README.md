# Attachment excel to mail using ALV 

### Here is a simple way to send ALV in excel attachments by email.

>Source code [here](https://github.com/Sgudkov/MAIL_ATTCH_EXCEL_BY_ALV/blob/main/MAIL_ATTCH.abap).


#### Explanation

*Get referance to ALV and get fieldcatalog*
```abap 

  GET REFERENCE OF lt_content_data INTO lt_data.
  ASSIGN lt_data->* TO <tab>.
  
  TRY .
      cl_salv_table=>factory(
      EXPORTING
        list_display = abap_false
      IMPORTING
        r_salv_table = lo_salv_table
      CHANGING
        t_table      = <tab> ).
    CATCH cx_salv_msg.

  ENDTRY.

  lo_columns  = lo_salv_table->get_columns( ).
  lo_aggreg   = lo_salv_table->get_aggregations( ).
  lt_fcat     = cl_salv_controller_metadata=>get_lvc_fieldcatalog(
                                r_columns      = lo_columns
                                r_aggregations = lo_aggreg ).

  ls_layout-col_opt = abap_true.

  lo_result_data = cl_salv_ex_util=>factory_result_data_table(
          s_layout                    = ls_layout
          r_data                      = lt_data
          t_fieldcatalog              = lt_fcat
      ).
``` 

*Transform result fetched in previous step to xstring and convert to solix*
```abap 
  lv_version = if_salv_bs_xml=>version_26.
  lv_file_type = if_salv_bs_xml=>c_type_excel_xml.
  lv_flavour = if_salv_bs_c_tt=>c_tt_xml_flavour_export.


  CALL METHOD cl_salv_bs_tt_util=>if_salv_bs_tt_util~transform
    EXPORTING
      xml_type      = lv_file_type
      xml_version   = lv_version
      r_result_data = lo_result_data
      xml_flavour   = lv_flavour
      gui_type      = if_salv_bs_xml=>c_gui_type_gui
    IMPORTING
      xml           = lv_xstring.

  t_objbin = cl_bcs_convert=>xstring_to_solix( lv_xstring ).
```   

*Finally fill table t_objpack and send transformed data in attachments*