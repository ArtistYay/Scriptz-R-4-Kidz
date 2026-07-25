def is_criticality_balanced(temperature, neutrons_emitted):
    if temperature < 800 and neutrons_emitted > 500 and temperature * neutrons_emitted < 500000:
        return True;
    else:
        return False;

is_criticality_balanced(625.99, 800)

#def is_criticality_balanced(temperature, neutrons_emitted):
#    if temperature < 800:
#        print('True')
#
#    elif neutrons_emitted > 500:
#        print('True')
#    
#    elif temperature * neutrons_emitted < 500000:
#        print('True')
#    
#    else:
#        print('False')
#    
#is_criticality_balanced(625.99, 800)

def reactor_efficiency(voltage, current, theoretical_max_power):
    generated_power = voltage * current
    efficiency = (generated_power / theoretical_max_power) * 100

    if efficiency >= 80:
        return "green"

    elif 80 > efficiency >=60:
        return "orange"

    elif 60 > efficiency >= 30:
        return "red"
    
    elif efficiency < 30:
        return "black"
    
    else:
        return "no more colors"

reactor_efficiency(200,50,15000)


def fail_safe(temperature, neutrons_produced_per_second, threshold):     
    status_code = "DANGER"
          
    criticality = temperature * neutrons_produced_per_second  
          
    if criticality < (threshold * 0.9):  
        status_code = "LOW"

    elif (threshold * 0.9) <= criticality <= (threshold * 1.1): 
        status_code = "NORMAL"

    return status_code