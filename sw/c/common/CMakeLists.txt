add_library(common OBJECT demo_system.c uart.c timer.c gpio.c pwm.c spi.c crt0.S and2.c
    example.c 
    k2c_activations.c 
    k2c_convolution_layers.c 
    k2c_core_layers.c 
    k2c_embedding_layers.c 
    k2c_helper_functions.c 
    k2c_merge_layers.c 
    k2c_normalization_layers.c 
    k2c_pooling_layers.c 
    k2c_recurrent_layers.c
)
target_include_directories(common INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}")
