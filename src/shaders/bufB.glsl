int binarySearchLeftMost(int part, int T, vec2 res, vec2 fragCoord) {
    mPartitionData pd = getPartitionData(sortedBuffer, fragCoord, res);
    int n = pd.particlesPerPartition;
    int maxPartition = getMaxPartition(pd);
    int L = maxPartition * n;
    int R = L + n;

    int i = 0;
    for (i = 0; i < maxBin && L < R; i++) {
        int m = (L + R) / 2;
        int Am = getM(part, m, res).Am;
        L = Am < T ? m + 1 : L;
        R = Am >= T ? m : R;
    }
    int ret = i < maxBin - 1 ? L : -1;
    return ret;
}

int binarySearchRightMost(int part, int T, vec2 res, vec2 fragCoord) {
    mPartitionData pd = getPartitionData(sortedBuffer, fragCoord, res);
    int n = pd.particlesPerPartition;
    int maxPartition = getMaxPartition(pd);
    int L = maxPartition * n;
    int R = L + n;

    int i = 0;
    for (i = 0; i < maxBin && L < R; i++) {
        int m = (L + R) / 2;
        int Am = getM(part, m, res).Am;
        L = Am <= T ? m + 1 : L;
        R = Am > T ? m : R;
    }
    int ret = i < maxBin - 1 ? L - 1 : -1;
    return ret;
}

float doDistance(int part, in vec2 fragCoord, vec2 colorUV) {
    vec2 res = maxRes;
    //vec2 oc = fragCoord / realRes * res;
    vec2 oc = fragCoord;

    int uvIndex = toIndex(colorUV);
    int index3 = binarySearchLeftMost(part, uvIndex, res, oc);
    int index4 = binarySearchRightMost(part, uvIndex, res, oc);

    mRet mret = getM(part, index3, res);
    int foundIndex = mret.Am;
    vec4 v = mret.v;
    float d = distance(colorUV, mret.pos);

    int j = 0;
    int a = min(index3, index4);
    int b = max(index3, index4);
    int maxIter = 10;
    int retIndex = -1;
    for (int j = 0; j < maxIter; j++) {
        int i = a + j - maxIter / 2;
        mRet mret = getM(part, i, res);
        int foundIndex = mret.Am;
        vec4 v = mret.v;
        float d2 = distance(colorUV, mret.pos);
        if (d2 < d) {
            d = d2;
            retIndex = i;
        }
    }

    return float(retIndex);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  //fragCoord = floor(fragCoord / iResolution.xy * maxRes);

	vec2 res = maxRes;
  // TODO: try +0.5
	vec2 colorUV = (fragCoord + 0.0) / realRes;

	vec4 old = texelFetch(pixelNearestBuffer, ivec2(fragCoord), 0);

    for (int part = 0; part < vec4Count; part++) {
    	float oldIndex = old[part];

        mRet mret1 = getM(part, int(oldIndex), res);
        float d2 = distance(colorUV, mret1.pos);

        float index = doDistance(part, fragCoord, colorUV);

        mRet mret2 = getM(part, int(index), res);

        float d3 = distance(colorUV, mret2.pos);

        index = d3 < d2 ? index : oldIndex;

        fragColor[PART] = index;
    }
}
