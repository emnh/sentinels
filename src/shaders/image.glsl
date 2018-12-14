// Fork of "Z Particle Sort Pipeline" by emh. https://shadertoy.com/view/Mtdyzs
// 2018-08-09 11:43:19

void lookup(out vec4 fragColor, in vec2 fragCoord) {
	vec2 res = maxRes;
    int k = 1;
    float mul = 1.0;
    const float MAX = 1.0e10;
    float rd = 0.0;
    float mind = MAX;
    vec2 colorUV = (fragCoord + 0.0) / realRes;
    vec3 color = vec3(1.0);
    int minIndex = -1;
    bool firstHalf = true;
    mPartitionData pd = getPartitionData(particleBuffer, fragCoord, res);

    vec4 indexAndVelNearest = texelFetch(pixelNearestBuffer, ivec2(fragCoord), 0);

    for (int dx = -k; dx <= k; dx++) {
        for (int dy = -k; dy <= k; dy++) {
            vec2 delta = vec2(dx, dy);
            //vec2 delta2 = vec2(sign(float(dx)) * exp2(abs(float(dx))), sign(float(dy)) * exp2(abs(float(dy))));

            ivec2 fc = ivec2(fragCoord + mul * delta);
            vec4 indexAndVel = texelFetch(pixelNearestBuffer, fc, 0);

            for (int part = 0; part < vec4Count; part++) {
                int i = int(indexAndVel[part]);
                mRet iret = getM(part, i, res);
                vec2 newPos = iret.pos;
                //vec2 newPos = vec2(fc) / realRes;
                float d = distance(colorUV, newPos);
                if (i >= 0 && d < mind) {
                    minIndex = iret.dIndex;
                    firstHalf = part == 0;
                }
                //mind = i < 0 ? mind : min(d, mind);
                mind = min(d, mind);
                //float f = 0.00005  / d;
                float f = d;
                rd = i < 0 ? rd : (d < (float(k) / realRes.x) ? f + rd : rd);
                if (i >= 0 && (d < (float(k) / realRes.x))) {
                    float h = float(iret.dIndex % pd.particlesPerPartition) / float(pd.particlesPerPartition);
                    color = hsv2rgb(vec3(h, 1.0, 1.0));
                    color = mix(vec3(1.0), color, d * iResolution.x / 10.0);
                	//fragColor += clamp(0.01 * vec4(color, 1.0) * vec4(1.0 / (d * realRes.x)), 0.0, 1.0);
                }
            }
        }
    }

    float h = float(minIndex % pd.particlesPerPartition) / float(pd.particlesPerPartition);
    color = hsv2rgb(vec3(h, 1.0, 1.0));
    color = mix(vec3(1.0), color, 100.0 * mind);

    float size = minIndex >= 0 ? float(minIndex % 10 + 1) : 1.0;

    float brightness = 1.0;
    //fragColor += clamp(brightness * vec4(color, 1.0) * vec4(1.0 / (mind * 1000.0)), 0.0, 1.0);
    fragColor += clamp(brightness * vec4(color, 1.0) * vec4(1.0 / (mind * realRes.x)), 0.0, 1.0);
    //fragColor += clamp(brightness * vec4(color, 1.0) * vec4(1.0 / (rd * realRes.x)), 0.0, 1.0);
    //fragColor = vec4(1.0 * rd);
}

void debug(out vec4 fragColor, in vec2 fragCoord) {
    vec4 v0 = texelFetch(iChannel0, ivec2(fragCoord), 0);
    vec4 v1 = texelFetch(iChannel1, ivec2(fragCoord), 0);
    vec4 v2 = texelFetch(iChannel2, ivec2(fragCoord), 0);
    vec4 v3 = texelFetch(iChannel3, ivec2(fragCoord), 0);
    //float val = float(int(v.w) % 1000) / 1000.0;
    float val = float(int(v0.x) % 10000) / 10000.0;
    fragColor = vec4(val);
    //fragColor.rb = v0.yz;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    //debug(fragColor, fragCoord);
    lookup(fragColor, fragCoord);
    //fragColor = vec4(vec3(0.5), 1.0);
    //fragColor = texture(iChannel1, fragCoord / iResolution.xy);
}
