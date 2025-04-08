shader_type canvas_item;

/**
Initial amplitude of the shock. This will start at this amplitude and
gradually attenuate.
*/
uniform float amplitude = 30.0;
/**
How fast shold it move side to side, more frequency means it'll move more quickly
side to side.
*/
uniform float frequecy = 10.0;
/**
Damping factor for the shake effect.
*/
uniform float damping = 3.0;
/**
Enable or disable the shake effect.
*/
uniform bool enabled = true;

void vertex() {
	if (enabled) {
		float exponent = mod(TIME, 3.0);
		VERTEX.x += amplitude * exp(-damping * exponent) * sin(frequecy * exponent);
	}
}