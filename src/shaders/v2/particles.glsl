const float E = 1.0e-10;

vec2 transformPos(vec2 pos) {
    pos = (pos - 0.5) * 4.0 + 0.5;
    pos = mod(pos, 1.0);
    return pos;
}

vec2 getSpring(vec2 res, vec4 particle, vec2 pos) {
    vec2 dv = particle.xy - pos;
    float l = length(dv);
    float k = 0.1;
    float s = sign(k - l);
    vec2 dvn = dv / (E + l);
    l = min(abs(k - l), l);

    float SPRING_COEFF = 1.0e2;
    float SPRING_LENGTH = 0.001;
    float X = abs(SPRING_LENGTH - l);
    float F_spring = SPRING_COEFF * X;

    if (l >= SPRING_LENGTH) {
    	dv = dvn * SPRING_LENGTH;
    }


    vec2 a = vec2(0.0);

    // Spring force
    a += -dv * F_spring;

    return a;
}

vec2 getGravity(vec2 res, vec4 particle, vec2 pos) {
    // Anti-gravity
    float MIN_DIST = 0.01;
    float G = 2.0e-1;
    float m = 1.0 / (MIN_DIST * MIN_DIST);
    vec2 dvg = particle.xy - pos.xy;
    float l2 = length(dvg);
    vec2 dvgn = dvg / l2;

    vec2 a = G * dvg / (MIN_DIST + m * l2 * l2);

    return a;
}

vec4 updateParticle(in vec4 particle, vec2 a) {
    vec2 v = particle.xy - particle.zw;

    v += a;
    v *= 0.5;

    if (particle.x + v.x < 0.0 || particle.x + v.x >= 1.0) {
        v.x = -v.x;
        v *= 0.5;
    }
    if (particle.y + v.y < 0.0 || particle.y + v.y >= 1.0) {
        v.y = -v.y;
        v *= 0.5;
    }

    float maxSpeed = 0.01;
    v = length(v) > maxSpeed ? maxSpeed * v / length(v) : v;

    particle.zw = particle.xy;
    particle.xy += v;

    return particle;
}

vec2 getPosition2(sampler2D channel, int index, vec2 res) {
    ivec2 fc = fromLinear(index, res);
    vec4 data = texelFetch(channel, fc, 0);
    return data.xy;
}

vec4 computeParticles(in vec2 fragCoord) {
    vec4 fragColor = vec4(0.0);
		vec2 res = iResolution.xy;

		vec2 oldPos = texelFetch(iChannel0, ivec2(fragCoord), 0).xy;
		vec2 pos = texelFetch(iChannel1, ivec2(fragCoord), 0).xy;
    vec4 particle1 = vec4(pos, oldPos);

		int particlesPerPartition = int(iResolution.x * iResolution.y);

    const int k = 16;
    const int k2 = 4;
    int w = int(sqrt(float(k)));
    vec2 a1 = vec2(0.0);
    vec2 a2 = vec2(0.0);
    //int torusCount = int(pow(2.0, float(int(iTime / 4.0) % 10)));
    int torusCount = 32;
    //int torusCount = 8;
    int particlesPerTorus = particlesPerPartition / torusCount;
    int wp = int(sqrt(float(particlesPerTorus)));
		int pdIndex = toLinear(fragCoord, res);
    int torus = pdIndex / particlesPerTorus;
    for (int i = 0; i < k; i++) {
        {
            int index = pdIndex % particlesPerTorus;
            vec2 fc = vec2(fromLinear(index, vec2(wp)));
            vec2 offset = vec2(i % w - w / 2, i / w - w / 2);
            if (torus % 3 == 0 && !justSentinels) {
								// Torus
								fc = fc + offset;
								fc = mod(fc, vec2(wp));
            } else if (torus % 3 == 1 && !justSentinels) {
								// Cloth
								fc = fc + offset;
								fc = clamp(fc, vec2(0.0), vec2(wp));
            } else {
								// Sentinel
								offset.x = -1.0;
								offset.y = 0.0;
								fc = fc + offset;
								fc = clamp(fc, vec2(0.0), vec2(wp));
								if (index % wp == 0) {
										fc = vec2(0.0);
								}
            }
            int j = toLinear(fc, vec2(wp)) + pdIndex - index;
            vec2 p2 = getPosition2(particleBuffer, j, res);
            a1 += getSpring(res, particle1, p2.xy) / float(w);
        }
        for (int i2 = 0; i2 < k2; i2++) {
            int w = int(sqrt(float(k)));
            int index = pdIndex % particlesPerTorus;
            int j =
                int(float(particlesPerTorus) *
                    hash(uvec2(fragCoord + float(i * k + i2) * vec2(13.0, 29.0) * vec2(iFrame))));
            j += pdIndex - index;
            vec2 p2 = getPosition2(particleBuffer, j, res);
            a1 += getGravity(res, particle1, p2.xy) / float(w * k2);
        }
    }

    vec2 updatedParticle = updateParticle(particle1, a1).xy;

		fragColor.xy = updatedParticle;
		// fragColor.zw = vec2(0.001 * float(torus + 1));

    return fragColor;
}

vec4 computeParticles2(in vec2 fragCoord) {
  vec4 fragColor = vec4(0.0);
  vec2 fc = fragCoord;
	if (iFrame == 0) {
		vec4 data = hash42(fc);
		vec2 particle = data.xy;
		fragColor.xy = particle;
	} else if (iFrame == 1) {
		vec4 data = hash42(fc);
		vec2 particle = data.xy + 0.001 * data.zw;
		fragColor.xy = particle;
	} else {
		fragColor = computeParticles(fragCoord);
	}
  return fragColor;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  fragColor = computeParticles2(fragCoord);
}
