
class Lab
	attr_reader :idx, :zone_idx
	def initialize(i, z, c, g)
		@idx = i
		@zone_idx = z
		@base_capa = c
		@growth_capa = g
	end

	def capacity(t)
		@base_capa + @growth_capa * t + noise
	end

	def noise
		rand(10) - 5
	end
end

class Zone
	attr_reader :idx, :lag
	def initialize(i, l)
		@idx = i
		@lag = l
	end

	def demand(t)
		[2**(t-lag) + noise, 0].max.to_i
	end

	def noise
		rand(10) - 5
	end
end

n_zones = 4
n_labs = 200

zones = (1..n_zones).map do |z|
	Zone.new z, 2*(z-1)
end

labs = (1..n_labs).map do |i|
	z = 1 + (i % n_zones)
	Lab.new i, z, (rand(z*50)), rand(20)
end

def serialize(zones, labs, steps, lifetime)
	demand_ary = zones.map{|z| (1..steps).map{|t| z.demand(t)}}.flatten
	transit_ary = zones.map{|z| labs.map{|l| if l.zone_idx == z.idx then 0 else 1 end}}.flatten
	capacity_ary = labs.map{|l| (1..steps).map{|t| l.capacity(t)}}.flatten
	[ "nLab = #{labs.length};",
	  "nZone = #{zones.length};",
	  "nTime = #{steps};",
	  "sample_lifetime = #{lifetime};",
	  "capacity = array2d(LAB,TIME,#{capacity_ary.to_s});",
	  "transit = array2d(ZONE,LAB,#{transit_ary.to_s});",
	  "demand = array2d(ZONE,TIME,#{demand_ary.to_s});"
	].join("\n")
end

if __FILE__ == $0
	puts serialize(zones, labs, 20, 2)
end
