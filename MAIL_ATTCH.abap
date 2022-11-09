
  DATA: t_objbin   TYPE STANDARD TABLE OF solix,
  	    t_objpack  TYPE STANDARD TABLE OF sopcklsti1,
  	    t_reclist  TYPE STANDARD TABLE OF somlreci1,
  	    wa_objpack TYPE sopcklsti1,
  	    wa_docdata TYPE sodocchgi1.

  DATA: lo_columns      TYPE REF TO cl_salv_columns_table,
  	    lo_salv_table   TYPE REF TO cl_salv_table
  	    lo_aggreg       TYPE REF TO cl_salv_aggregations,
  	    lt_fcat         TYPE lvc_t_fcat,
  	    ls_layout       TYPE lvc_s_layo,
  	    lo_result_data  TYPE REF TO cl_salv_ex_result_data_table,
  	    lt_data         TYPE REF TO data,
  	    lv_version      TYPE string,
  	    lv_file_type    TYPE salv_bs_constant,
  	    lv_flavour      TYPE string,
  	    lv_xstring      TYPE xstring,
  	    lv_cnt          TYPE i,
  	    lt_content_data TYPE TABLE OF ZSTRUCTURE. "Put your structure here

  FIELD-SYMBOLS: <tab> TYPE ANY TABLE.	  

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
  
  wa_objpack-transf_bin = 'X'.
  wa_objpack-head_start = 1.
  wa_objpack-head_num   = 1.
  wa_objpack-body_start = 1.
  wa_objpack-body_num   = LINES( t_objbin ).
  wa_objpack-doc_type   = 'XLS'.
  wa_objpack-obj_name   = 'NAME.xls'.
  wa_objpack-obj_descr  = 'DESCR.xls'.
  wa_objpack-doc_size   = wa_objpack-body_num * 255.
  APPEND wa_objpack TO t_objpack.
  
  wa_docdata-obj_name  = 'MAILATTCH'.
  wa_docdata-sensitivty   = 'F'.
  lv_cnt = LINES( t_objbin ).
  wa_docdata-doc_size = ( lv_cnt - 1 ) * 255 + XSTRLEN( lv_xstring ).
  wa_docdata-obj_descr = 'Your description'.	
  
  "t_reclist - append your receivers here
  
  CALL FUNCTION 'SO_NEW_DOCUMENT_ATT_SEND_API1'
  EXPORTING
    document_data              = wa_docdata
    put_in_outbox              = 'X'
    commit_work                = 'X'      
  TABLES
    packing_list               = t_objpack  
    contents_hex               = t_objbin
    receivers                  = t_reclist
  EXCEPTIONS
    too_many_receivers         = 1
    document_not_sent          = 2
    document_type_not_exist    = 3
    operation_no_authorization = 4
    parameter_error            = 5
    x_error                    = 6
    enqueue_error              = 7
    OTHERS                     = 8.
  IF sy-subrc EQ 0.
    COMMIT WORK. 
  ENDIF.
	