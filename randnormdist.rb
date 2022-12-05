#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009) in 2020
#Code updated and modified in 2022

#Generate random numbers from normal distrubution
#Using Box-Muller transformation
class RandNormDist
    attr_accessor :mean, :sd

    def initialize(mean=0, sd=0)
        @mean = mean.to_f
        @sd = sd.to_f
        @rand_func = lambda { Kernel.rand }
    end

    #generate random float value from normal distribution
    def rand
        theta = 2 * Math::PI * @rand_func.call
        rho = Math.sqrt(-2 * Math.log(1 - @rand_func.call))
        scale = @sd * rho
        return @mean + scale * Math.cos(theta)
    end

    #generate random value, convert to int and take absolute value
    def rand_ticks
        return rand.to_i.abs
    end
end
