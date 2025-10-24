//
//  Constents.h
//  CarLinkChannel
//
//  Created by job on 2023/3/27.
//

#ifndef Constents_h
#define Constents_h
#import <CocoaLumberjack/CocoaLumberjack.h>

#define remote_ip @"169.254.71.43"
#define gateway_ip @"169.254.255.255"
#define gateway_port 6811
#define local_port 23456
#define remote_tcp_port 6801


// 指令部分

#define send_datapacket_boardcast {0x00, 0x00, 0x00 ,0x00 ,0x00,0x11}

#define send_datapacket_vin @"000000050001f41822f190"
#define recv_datapacket_vin_prefix @"000000050002f41822f190"
#define send_datapacket_svt @"000000050001f41822f101"
#define recv_datapacket_svt_prefix @"000000050002f41822f101"

#define recv_vin_length 22
#define recv_svt_length 22
#define recv_cafd_length 22
#define anquan_suanfa_start_index 20
#define anquan_suanfa_min_len 26
#define recv_vin_f190_index 18
#define recv_svt_f101_index 18

#define packet_obj 11
#define packet_seq 16
#define packet_error_9 16
#define packet_error_11 20
#define packet_len_min 22
#define packet_df_index 14
#define packet_speed_index 22

#define packet_from_board @"2"
#define packet_from_ecu @"1"
#define packet_error_9_byte @"7f"
#define packet_error_11_byte @"78"
#define packet_vin @"f190"
#define packet_svt @"f101"
#define packet_not_check @"df"
#define packet_speed_test @"0112f4"
#define packet_recv_mark @"0118f4"
#define packet_send_mark @"01f418"

// cafd相关指令
#define send_datapacket_cafd_1 @"000000050001f418223000"
#define send_datapacket_cafd_2 @"000000050001f418223001"
#define send_datapacket_cafd_3 @"000000050001f418223002"
#define send_datapacket_cafd_4 @"000000050001f418223003"
#define send_datapacket_cafd_5 @"000000050001f418223004"

#define recv_datapacket_cafd_container @"0118f4"
#define recv_datapacket_fault_dme_container @"0112f45902"
#define recv_datapacket_fault_egs_container @"0118f45902"
#define recv_dtapacket_fault_tcu_pressure_container @"0000000f000118f462413a"
#define recv_datapacket_fault_fast_fill_container @"0000000f000118f4624140"

// 安装程序指令

#define binheader @"0099"
#define condition_on @"11"
#define attribute_00 @"00"
#define attribute_01 @"01"
#define attribute_03 @"03"

#define front1_data_packet_1 @"00 00 00 04 00 01 f4 12 3e 80"
#define front2_data_packet_1 @"00 00 00 04 00 01 f4 18 10 01"
#define front2_data_packet_2 @"00 00 00 06 00 01 f4 18 31 01 02 03"
#define front2_data_packet_3 @"00 00 00 04 00 01 f4 18 10 03"
#define front2_data_packet_4 @"00 00 00 07 00 01 f4 18 31 01 0F 0C 03"
#define front2_data_packet_5 @"00 00 00 04 00 01 f4 18 85 02"
#define front2_data_packet_6 @"00 00 00 05 00 01 f4 18 28 01 01"
#define front2_data_packet_7 @"00 00 00 07 00 01 f4 18 31 01 10 03 01"

#define safe_data_packet_1 @"00 00 00 04 00 01 f4 18 10 02"
#define safe_data_packet_2 @"00 00 00 08 00 01 f4 18 27 11 ff ff ff ff"
#define safe_data_packet_3_unit_1 @"00 00 00 48 00 01 f4 18 27 12"
#define safe_data_packet_4 @"00 00 00 12 00 01 f4 18 2e f1 5a 17 11 30 8f 04 d2 01 00 00 0B BB 00 00"

#define send_data_packet_1_1_unit_1 @"00 00 00 0d 00 01 f4 18 31 01 ff 00 02 40"
#define send_data_packet_3_1 @"00 00 00 0c 00 01 f4 18 31 01 ff 00 02 40 09 77 fd 00"
#define send_data_packet_3_2 @"00 00 00 0c 00 01 f4 18 31 01 ff 00 02 40 09 67 fd 00"
#define send_data_packet_3_3 @"00 00 00 0c 00 01 f4 18 31 01 ff 00 02 40 09 03 fd 00"

#define send_data_xmlzz_packet_unit_1 @"00 00 00 0d 00 01 f4 18 34"

#define send_bin_data_unit1 @"00 00 0B BB 00 01 f4 18 36"
#define send_bin_data_last_header @"00 01 f4 18 36"

#define send_data_end_1 @"00 00 00 04 00 01 f4 df 3e 80"
#define send_data_end_2 @"00 00 00 03 00 01 f4 18 37"


#define check_succ_packet_1_unit_1 @"00 00 00 0e 00 01 f4 18 31 01 02 02 12 40"
#define check_succ_end_packet_2 @"00 00 00 06 00 01 f4 18 31 01 ff 01"

#define send_1101_data_packet @"00 00 00 04 00 01 f4 18 11 01"
#define send_spec_data_packet_1 @"00 00 00 04 00 01 f4 18 10 03"
#define send_spec_data_packet_2 @"00 00 00 07 00 01 f4 18 31 01 0f 0c 03"
#define send_spec_data_packet_3 @"00 00 00 04 00 01 f4 18 85 02"
#define send_spec_data_packet_4 @"00 00 00 05 00 01 f4 18 28 01 01"
#define send_spec_data_packet_5 @"00 00 00 07 00 01 f4 18 31 01 10 03 01"
#define send_spec_data_packet_6 @"00 00 00 04 00 01 f4 18 10 01"
#define send_spec_data_packet_7 @"00 00 00 04 00 01 f4 18 10 03"


#define send_end_1_packet_1 @"00 00 00 06 00 01 f4 18 31 01 ff 01"
#define send_end_1_packet_2_unit_1 @"00 00 00 16 00 01 f4 18 2e f1 90"
#define send_end_1_packet_3 @"00 00 00 04 00 01 f4 18 11 01"
#define send_end_1_packet_4 @"00 00 00 04 00 01 f4 18 10 03"
#define send_end_1_packet_5 @"00 00 00 07 00 01 f4 18 31 01 0f 0c 00"
#define send_end_1_packet_6 @"00 00 00 05 00 01 f4 18 22 f1 01"
#define send_end_1_packet_7 @"00 00 00 04 00 01 f4 18 10 01"
#define send_end_1_packet_8 @"00 00 00 04 00 01 f4 18 10 03"

#define send_end_2_packet_1 @"00 00 00 04 00 01 f4 18 10 41"
#define send_end_2_packet_2 @"00 00 00 08 00 01 f4 18 27 01 ff ff ff ff"
#define send_end_2_packet_3_unit_1 @"00 00 00 48 00 01 f4 18 27 02"




#define send_cafd_packet_1 @""


#define send_end_3_packet_1 @""


#define send_end_4_packet_1 @"00 00 00 06 00 01 f4 18 31 01 0f 01"
#define send_end_4_packet_2_unit_1 @"00 00 00 0c 00 01 f4 18 2e 37 fe"
#define send_end_4_packet_3 @"00 00 00 04 00 01 f4 18 11 01"
#define send_end_4_packet_4 @"00 00 00 06 00 01 f4 df 14 ff ff ff"
#define send_end_4_packet_5 @"00 00 00 0d 00 01 f4 f0 b1 01 0f 0b df 00 04 b1 01 0f 06"
#define send_end_4_packet_6 @"00 00 00 05 00 01 f4 18 22 f1 01"


#define send_anquan_packet_req @"00 00 00 07 00 01 f4 18 2e 30 00 10 b2"
#define send_anquan_packet_res_untity_1 @"00 00 00 89 00 01 f4 18 2e 30 03"


#define recv_anquan_1_prefix @"00 00 00 0c 00 01 18 f4 67 11"
#define recv_anquan_2_prefix @"00 00 00 0c 00 01 18 f4 67 01"
#define recv_anquan_3_prefix @"00 00 00 0d 00 01 f4 18 2e 30"

#define recv_var3 @"00 00 00 0c 00 01 18 f4 67 11 ff ff ff f8 bb ac bb bf"
#define recv_var3_2 @"00 00 00 0c 00 01 18 f4 67 01 ff bf e5 38 b4 e0 e6 db"
#define recv_var3_3 @"00 00 00 0d 00 01 f4 18 2e 30 02 05 00 00 02 3f 10 10 27"

// 第六个分支
#define sero_6_datapacket_1 @"00 00 00 12 00 01 f4 18 2e f1 5a 23 05 16 8f 04 d2 01 00 00 10 00 00 00"


// 第二个分支的包与第一个分支的包部分不一样
#define sero_2_datapcket_1_anquan_prefix @"00 00 00 88 00 01 f4 18 27 12"
#define sero_2_datapcket_1 @"00 00 00 12 00 01 f4 18 2e f1 5a 19 03 05 8d 02 62 01 00 00 00 35 00 00"

#define sero_2_datapacket_3 @"00 00 00 88 00 01 f4 18 27 02"

// 第三个分支
#define sero_3_datapcket_1_anquan_prefix @"00 00 00 88 00 01 f4 18 27 12"
#define sero_3_datapcket_1 @"00 00 00 12 00 01 f4 18 2e f1 5a 19 03 05 8d 02 62 01 00 00 00 35 00 00"

#define sero_3_datapackt_anquan_prefix @"00 00 00 88 00 01 f4 18 27 02"


// 第四个分支
#define sero_4_datapacket_1 @"00 00 00 12 00 01 f4 18 2e f1 5a 17 11 30 8f 04 d2 01 00 00 10 00 00 00"
#define sero_4_bin_prefix @"00 00 07 04 00 01 f4 18 36"

#define sero_4_datapacket_2 @"00 00 00 06 00 01 f4 18 31 01 ff 01"
#define sero_4_datapacket_3 @"00 00 00 16 00 01 f4 18 2e f1 90"
#define sero_4_datapacket_4 @"00 00 00 04 00 01 f4 18 11 01"





//
#define recv_datapacket_020200 @"00000007000118f47101020200"
#define recv_datapacket_020201 @"00000007000118f47101020201"

// 0-100 测速相关指令

#define send_datapacket_test_1 @"00 00 00 06 00 01 F4 12 2C 03 F3 00"
#define recv_datapacket_test_1_1 @"00 00 00 06 00 02 F4 12 2C 03 F3 00"
#define recv_datapacket_test_1_2 @"00 00 00 06 00 01 12 F4 6C 03 F3 00"

#define send_datapacket_test_2 @"00 00 00 1A 00 01 F4 12 2C 01 F3 00 58 14 01 02 42 05 01 02 58 19 01 02 58 81 01 01 58 0D 01 02"
#define recv_datapacket_test_2_1 @"00 00 00 07 00 02 F4 12 2C 01 F3 00 58"

// 第一个分支 的回复
#define recv_datapacket_test_2_2 @"00 00 00 06 00 01 12 F4 6C 01 F3 00"
// 第二个分支 的回复
#define recv_datapacket_test_2_2_mevd @"00 00 00 05 00 01 12 F4 7F 2C 31"

#define send_datapacket_test_3_1_mevd @"00 00 00 1A 00 01 f4 12 2c 01 f3 00 58 14 01 01 42 05 01 02 58 19 01 02 58 81 01 01 58 0d 01 01"

#define send_datapacket_test_3 @"00 00 00 05 00 01 f4 12 22 f3 00"
#define recv_datapacket_test_3_1 @"00 00 00 05 00 02 f4 12 22 f3 00"
#define recv_datapacket_test_3_2 @"00 00 00 0E 00 01 12 F4 62 F3 00 00 00 37 B3 00 00 00 00 00"  // 这条数据关键
#define speed_test_datapacket_sero_1_prefix @"00 00 00 0E 00 01 12 F4 62 F3 00"
#define speed_test_datapacket_sero_2_prefix @"0000000c000112f462f300"

#define recv_datapacket_broadcast @"000000050002f41222f300"
// 测速第二个分支



// 进入诊断模式
#define send_datapacket_diagnostic @"000000090001f440310110010a0a43"
// Fault Code DTC （故障码读取）
#define send_datapacket_fault_code @"000000050001f4df19020c"
// 清除故障码
#define send_datapacket_fault_clear @"000000060001F4DF14FFFFFF"
// 删除车辆运输模式
#define send_datapacket_transport_mode_1 @"000000070001F41831010F0C00"
#define send_datapacket_transport_mode_2 @"000000070001F41231010F0C00"
#define send_datapacket_transport_mode_3 @"000000070001F46331010F0C00"

//EGS 健康度
//TCU filling pressure （离合器加注压力）
#define send_datapacket_tcu_fill_pressure @"000000050001f41822413a"
// fast filling time
#define send_datapacket_fast_fill_time @"000000050001f418224140"

// tcu learning reset
#define send_datapacket_tcp_reset @"000000060001f4182e415000"


// 点击开始按钮之后调用的指令
#define send_datapacket_start @"00 00 00 09 00 01 f4 40 31 01 10 01 0a 0a 43"

// 通知部分

#define recv_udp_notify_name  @"recv_udp_notify"
#define recv_vin_notify_name @"recv_vin_notify"
#define recv_svt_notify_name @"recv_svt_notify"
#define recv_anquan_notify_name @"recv_anquan_notify"

#define recv_tcp_cafd_1_notify_name @"recv_tcp_cafd_1_notify"
#define recv_tcp_cafd_2_notify_name @"recv_tcp_cafd_2_notify"
#define recv_tcp_cafd_3_notify_name @"recv_tcp_cafd_3_notify"
#define recv_tcp_cafd_4_notify_name @"recv_tcp_cafd_4_notify"
#define recv_tcp_cafd_5_notify_name @"recv_tcp_cafd_5_notify"
#define recv_tcp_speed_test_notify_name @"recv_tcp_speed_test_notify"


// 下载相关通知

#define start_package_notify_name @"start_package_notify"
#define down_package_notify_name @"down_package_notify"
#define done_package_notify_name @"done_package_notify"
#define fail_down_package_notify_name @"fail_down_package_notify"

// 安装的通知

#define begin_start_install_notify_name @"start_install_notify"
#define install_notify_name @"install_notify"
#define ecu_file_done_install_notify_name @"ecu_file_done_install_notify"
#define done_install_notify_name @"done_install_notify"
#define fail_install_notify_name @"fail_install_notify"
#define install_file_read_notify_name @"install_file_read_notify"
#define begin_start_recovery_notify_name @"begin_start_recovery_notify"
#define done_recovery_notify_name @"done_recovery_notify"
#define fail_recovery_notify_name @"fail_recovery_notify"
#define tcp_disconnect_notify_name @"tcp_disconnect_notify"
#define tcp_security_timeout_notify_name @"tcp_security_timeout_notify"
#define data_send_fail_notify_name @"data_send_fail_notify"

// 故障码读取的通知
#define recv_data_dme_notify_name @"recv_data_dme_notify"
#define recv_data_egs_notify_name @"recv_data_egs_notify"

// egs 健康度的通知
#define recv_data_egs_health_clutch_notify_name @"recv_data_egs_health_clutch_notify"
#define recv_data_egs_health_fill_notify_name @"recv_data_egs_health_fill_notify"

#define FLASH_BREAK_REASON_NOTIFY_NAME @"FLASH_BREAK_REASON_NOTIFY"
//激活通知
#define activation_notify_name @"activation_notify"

// 测速相关通知
#define recv_speed_test_package_1_notify_name @"recv_speed_test_package_1_notify"
#define recv_speed_test_package_2_sero_1_notify_name @"recv_speed_test_package_2_sero_1_notify"
#define recv_speed_test_package_2_sero_2_notify_name @"recv_speed_test_package_2_sero_2_notify"
#define recv_speed_test_package_3_sero_2_notify_name @"recv_speed_test_package_3_sero_2_notify"
#define recv_speed_test_timeout_notify_name @"recv_speed_test_timeout_notify"

// 开始准备的通知
#define recv_speed_ready_notify_name @"recv_speed_ready_notify"
// 开始计时的通知
#define recv_speed_time_start_notify_name @"recv_speed_time_start_notify"
// 结束计时的通知
#define recv_speed_stop_timer_notify_name @"recv_speed_stop_timer_notify"

// 视频合成通知
#define recv_video_progress_notify_name @"recv_video_progress_notify"
#define recv_video_progress_done_notify_name @"recv_video_progress_done_notify"
#define recv_video_add_time_labe_notify_name @"recv_video_add_time_labe_notify"
#define progress_count @"progress_count"
#define prgress_video @"prgress_video"

#define tune_txt_name @"show.txt"
#define tune_bin_name @"tune.bin"
#define list_file_unkw @"list_file_unkw"


#define Local_network @"Local_network"
#define Local_ip @"Local_ip"
#define Remote_ip @"Remote_ip"

#define FLASH_BREAK_REASON_KEY @"reason"

// 文件服务器和http服务器
#define HTTP_HOST @"http://39.105.185.193:8089"
#define FILE_HOST @"http://82.157.7.102:8001"

// ftp 相关配置信息
#define FTP_HOST @"wh-ibe9tnoqwbchq8itu.my3w.com"
#define FTP_USER_NAME @"wh-ibe9tnoqwbchq8itu"
#define FTP_PASSWORD @"Q1w2e3r4"
#define FTP_PORT 21

// binary 相关配置信息
#define BINARY_FILE_KEY @"binname"
#define SHOW_TXT @"show.txt"
#define TUNE_BIN @"tune.bin"
#define RECOVERY_CAFD_FILE_NAME @"Recovery.CAFD"
#define UPDATE_FILE_NO_FILE @"no_file"

// 判断是否有internet网络连接
#define Connect_Internet @"http://39.105.185.193:8089/BWMSeurityCheck/GetBwmSeurity?var1=65&var2=BTLD_000034AC_002_156_007&var3=01%2C21%2C54%2CE3%2CFC%2CF3%2CDF%2C39"

// 获取安全算法安全值
#define anquan_suanfa_url @"http://39.105.185.193:8089/BWMSeurityCheck/GetBwmSeurity?var1=65"


// 根据vin获取激活码接口
#define Content_Vin @"http://82.157.7.102:8000/api/CardKey/GetVinInfo?vin="

#define RegisterVinBin @"http://82.157.7.102:8004/api/Register"

// 根据激活码和vin查询是否激活
#define Valid_Vin @"http://82.157.7.102:8000/api/CardKey/IsValid?txt="

// 使用激活码去激活设备
#define ValidWithCode @"http://82.157.7.102:8000/api/CardKey/IsValid?txt="

// list.txt 匹配bin文件的规则接口
#define GetList @"http://82.157.7.102:8000/api/CardKey/GetList"

// 查看Bin文件更新的接口
#define GetBinNew @"http://82.157.7.102:8000/api/CardKey/GetNewUpdateInfo?vin="
//#define GetBinNew @"http://43.135.148.212:8000/api/CardKey/GetNewUpdateInfo?vin="

// 当前用户的vin文件路径
#define vin_file_path @"vin_file_path"

// 处理list规则接口常量
#define list_vin @"VIN"
#define list_sw  @"SW"
#define list_btld @"BTLD"
#define list_unkw @"UNKW"
// 处理 sgbms 相关分支
#define swfl_prefix @"SWFL"
#define btld_prefix @"BTLD"
#define hwel_prefix @"HWEL"
#define vin_prefix  @"vin"
#define svt_separated @"_"


// 区分分支的相关常量
#define HWEL @"HWEL"
#define HWEL_22A @"HWEL_0000022A"
#define HWEL_22B @"HWEL_0000022B"
#define HWEL_BBD @"HWEL_00001B8D"
#define HWEL_22AE @"HWEL_000022AE"
#define HWEL_22E9 @"HWEL_000022E9"
#define HWEL_1F6A @"HWEL_00001F6A"
#define HWEL_4326 @"HWEL_00004326"
#define HWEL_435F @"HWEL_0000435F"
#define BTLD_5F6D @"BTLD_00005F6D"
#define BTLD_5F6E @"BTLD_00005F6E"
#define CAFD_FFFF @"CAFD_FFFFFFFF_255_255_255"

// 日志前缀部分
#define date_prefix @"Date:"
#define ecu_prefix  @"Ecu:"
#define cafd_prefix @"Cafd:"
#define count_prefix @"Count:"
#define start_flag @"----------start----------"
#define end_flag   @"----------end----------"
#define date_format @"yyyy-MM-dd HH:mm:ss"
#define info_prefix @"[INFO] "
#define warn_prefix @"[WARN] "
#define error_prefix @"[ERROR] "
#define flash_stage @"flash_stage"

// 刷写完成的字符
#define DONE_WRITE_TCP_TITLE @"TCU Program Completed."
#define FAIL_FLASH_CAFD_TITLE @"CAFD Recovery Fail."
#define DONE_WRITE_TCP_CONTENT @"Please lock and sleep the vehicle for 30 seconds before igniting again. "
#define DONE_WRITE_ALLOW_TEXT @"Done"
#define NO_CAFD_CONTENT @"No CAFD found, Please double check TCU SVT info."
#define TCU_UNLOCK_REQUIRE @"TCU Unlock require"
#define RECOVERY_CAFD @"Please recovery CAFD first."
#define ECU_UNSUPPORTED @"ECU Unsupported. Please waiting next general release."
#define TCU_UNLOCK_CONTENT @"TCU Unlock require. Please using unlock device to unlock before tuning. "
#define TCU_UPGRADE_CONTENT @"TCU version Un-support, Please upgraded TCU BTLD version."
#define CAFD_DATA_READING_CONTENT @"Reading CAFD data."
#define CAFD_DATA_READ_CONTENT @"CAFD data reading and backup."
#define READ_DATA_FROM_REMOTE_CONTENT @"online checking vehicle status."
#define CAR_NOT_REGISTER_CONTENT @"Please Active vehicle to continue tuning."
#define CAR_RECONDITIONING_CONTENT @"Activation failed, please contact ZD8 support. "

#define CAR_REGISTER_CONTENT @"OTS MAPS ready, Please continue to tuning."
#define CAFD_FILE_NOT_CORRECT @"CAFD file not correct, If need restore please using OTS MAPS' ZD8 Recovery Tool to restore. "
#define WRITE_DONE_SUCC_CONTENT @"Programing successful."
#define ACTIVATION_SUCCESS_CONTENT @"Activation Success"
#define TCP_DISCONNECT_TITLE @"Vehicle Disconnect"
#define TCP_DISCONNECT_CONTENT @"Please double check ENET connection correct."
#define WAIT_SERVER_DATA_CONTENT @"Waiting Server data. Please wait."
#define FAIL_FLASH_FILE_TITLE @"Flashing Error"
#define FAIL_FLASH_FILE_CONTENT @"Please re-flash TCU again or Uninstall to restore. "
#define TIMEOUT_TITLE @"Security access timeout."
#define TIMEOUT_CONTENT @"Please re-flash again."
#define CONTACT_EMAIL_CONTENT @"Please contact us email:support@zd8.org"
#define DATA_ERROR_CONTENT @"Data Error Please use \"OBD Unlock -STEP 1\" to re-Programing."
#define CLEAR_RECORD_CONTENT @"Please confirm whether to clear all test records."
#define CONTINUE_TUNING @"Please continue the tuning operation."
#define FAIL_FLASH_BASE_CONTENT @"Please perform OBD 'Unlock - STEP1' before proceeding.. "
#define FAIL_FLASH_BASE_RECOVER @"Please use Re-Flash OBD Unlock to continue programing. "



// 测试速模块
#define SPEED_TEST_CELL @"HistoryTestCell"



#define Vehicle_Connect_Success @"Vehicle_Connect_Success_notify"

#define FTP_CAFD_URL @"/ZD8-TCU-CAFD"
#define FTP_MID_PATH @"/ZD8-TCU-mid"
#endif /* Constents_h */
