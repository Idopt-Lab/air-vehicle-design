%{
In complex systems, you often have different types of objects that share core 
behaviors but have specific differences. Instead of copying and pasting code, 
you can use Inheritance to create a parent class (Superclass) and child classes (Subclasses).

Imagine you are modeling different types of aircraft. 
You can create a broad Aircraft class that handles basic physics (mass, drag, velocity). 
Then, you can create a specific eVTOL class that inherits all the properties of Aircraft,
 but adds specific properties for rotors and battery management.


%}

% The child class 'eVTOL' inherits from the parent class 'Aircraft'
classdef eVTOL < Aircraft 
    properties
        BatteryCapacity
        RotorCount
    end
    
    methods
        function hover(obj)
            % Specific behavior just for eVTOLs
        end
    end
end