# 1. 클럭 정의 (24MHz 카메라 클럭 기준: 주기 41.66ns)
create_clock -name p_clock -period 41.66 [get_ports p_clock]

# 2. 클럭 불확실성 (Jitter 및 Margin 확보)
set_clock_uncertainty 0.5 [get_clocks p_clock]

# 3. Input Delay 설정
# 외부(카메라)에서 들어오는 신호들이 클럭 엣지 후 최대 2ns 이내에 도착한다고 가정
set_input_delay -max 2.0 -clock p_clock [get_ports {rst vsync href p_data[*]}]

# 4. Output Delay 설정
# 이 모듈의 출력 신호들이 다음 모듈에 도달하기 전 2ns의 마진을 요구한다고 가정
set_output_delay -max 2.0 -clock p_clock [get_ports {pixel_data[*] frame_done o_x_count[*] o_y_count[*] pixel_valid}]
