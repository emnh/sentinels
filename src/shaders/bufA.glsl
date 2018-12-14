// Resources:
// https://www.ics.uci.edu/~goodrich/pubs/skip-journal.pdf
// Sorting with GPUs: A Survey: https://arxiv.org/pdf/1709.02520.pdf

// Practice JavaScript implementation: http://jsbin.com/zeyiraw/

// https://www.shadertoy.com/view/XlcGD8
// https://developer.nvidia.com/gpugems/GPUGems2/gpugems2_chapter46.html
// https://stackoverflow.com/questions/26093629/glsl-odd-even-merge-sort
// https://bl.ocks.org/zz85/cafa1b8b3098b5a40e918487422d47f6

// #define resetPressed (texelFetch(iChannel1, ivec2(KEY_LEFT,1),0 ).x > 0.5)

const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;

int extractIndex(vec4 v, int part) {
    return int(v[PART]);
}

int getIndex(int part, mRet A, vec2 res) {
    return A.Am;
}

bool compare(int part, mRet A, mRet B, vec2 res) {
    return getIndex(part, A, res) < getIndex(part, B, res);
}

bool cutValid(int part, int n1, int n2, int astart, int bstart, int to, int m2, int x, vec2 res) {
    int apos = m2 - 1;
    bool aValid = apos >= 0 && apos < n1;
    int bpos = to - m2 - 1;
    bool bValid = bpos >= 0 && bpos < n2;

    mRet Amret = getM(part, astart + apos, res);
    mRet Bmret = getM(part, bstart + bpos, res);

    int cv11 = getIndex(part, Amret, res);
    int cv12 = getIndex(part, Bmret, res);
    return (
        aValid && bValid && apos >= 0 && bpos >= 0 ? max(cv11, cv12) <= x
        : bValid && apos < 0 && bpos >= 0 ? cv12 <= x
        : aValid && apos >= 0 && bpos < 0 ? cv11 <= x
        : Amret.valid && Bmret.valid);
}

bool cutCValid(int part, int n1, int n2, int astart, int bstart, int to, int bm2, int x, vec2 res) {
    int apos = to - bm2 - 1;
    int bpos = bm2 - 1;
    bool aValid = apos >= 0 && apos < n1;
    bool bValid = bpos >= 0 && bpos < n2;

    mRet Amret = getM(part, astart + apos, res);
    mRet Bmret = getM(part, bstart + bpos, res);
    int cvc11 = getIndex(part, Amret, res);
    int cvc12 = getIndex(part, Bmret, res);
    return (
    	aValid && bValid && apos >= 0 && bpos >= 0 ? max(cvc11, cvc12) <= x
        : bValid && apos < 0 && bpos >= 0 ? cvc12 <= x
        : aValid && apos >= 0 && bpos < 0 ? cvc11 <= x
        : Amret.valid && Bmret.valid);
}

mRet checkIndex(int part, int n1, int n2, int astart, int bstart, int to, int apos, vec2 res) {
    bool aValid = apos >= 0 && apos < n1;
    int bpos = to - apos;
    bool bValid = bpos >= 0 && bpos < n2;

    mRet Amret = getM(part, astart + apos, res);
    mRet Bmret = getM(part, bstart + bpos, res);

    int candA = getIndex(part, Amret, res);
    bool candAv = cutValid(part, n1, n2, astart, bstart, to, apos, candA, res) && aValid;
    Amret.valid = Amret.valid && candAv;

    int candB = getIndex(part, Bmret, res);
    bool candBv = cutCValid(part, n1, n2, astart, bstart, to, bpos, candB, res) && bValid;
    Bmret.valid = Bmret.valid && candBv;

    if (candAv && candBv) {
        if (candA < candB) {
            return Amret;
        } else {
            return Bmret;
        }
    } else if (candAv) {
        return Amret;
    }
    return Bmret;
}

mRet binarySearchForMergeSlim(
    int part,
    int targetOffset, int n1, int n2, vec2 res,
    int astart, int bstart) {

    int L1 = min(max(targetOffset + 1 - n1, 0), n1 - 1);
    int R1 = min(targetOffset + 1, n1);
    int L2 = min(max(targetOffset + 1 - n2, 0), n2 - 1);
    int R2 = min(targetOffset + 1, n2);

    int OL1 = L1;
    int OR2 = R2;

    int i = 0;

    mRet ret;

    bool bValid = true;

    for (i = 0; i < maxBin && L1 < R1 && (L2 < R2 || !bValid); i++) {
        int m = (L1 + R1) / 2 + (L1 + R1) % 2;
        int bm = targetOffset - m;
        int apos = m;
        bool aValid = apos >= 0 && apos < n1;
        int bpos = bm;
        bValid = bpos >= 0 && bpos < n2;

        mRet Amret = getM(part, astart + apos, res);
        aValid = aValid && Amret.valid;
        mRet Bmret = getM(part, bstart + bpos, res);
        bValid = bValid && Bmret.valid;

        bool comparison = compare(part, Amret, Bmret, res) && aValid && bValid;
        bool inUpperHalf = comparison;

        // m + 1 to R1
        L1 = inUpperHalf ? m : L1;
        // L1 to m
        R1 = !inUpperHalf ? m - 1 : R1;
        // bm + 1 to R2
        L2 = !inUpperHalf ? bm : L2;
        // L2 to bm
        R2 = inUpperHalf ? bm : R2;
    }
    mRet error = mRet(-1, -1, vec4(-1.0), vec4(-1.0), vec2(-1.0), false);
    //mRet error = mRet(-1, vec4(-1.0), false);

    int apos = L1;
    int bpos = targetOffset - L1;
    bValid = bpos >= 0 && bpos < n2;

    mRet AL1ret = getM(part, astart + apos, res);
    mRet BL1ret = getM(part, bstart + bpos, res);
    //return AL1ret;

    // XXX: AL1ret and BL1ret should be valid I hope
    int m2 = getIndex(part, AL1ret, res) < getIndex(part, BL1ret, res) && bValid ? L1 + 1 : L1;
    int bm2 = OR2 - (m2 - OL1);
    bool bm2Valid = bm2 >= 0 && bm2 < n2;
    bool bm2Min1Valid = bm2 - 1 >= 0 && bm2 - 1 < n2;

    int to = targetOffset;

    mRet cand1 = checkIndex(part, n1, n2, astart, bstart, to, m2, res);
    mRet cand2 = checkIndex(part, n1, n2, astart, bstart, to, bm2, res);
    cand2.valid = cand2.valid && bm2Valid;
    mRet cand3 = checkIndex(part, n1, n2, astart, bstart, to, m2 - 1, res);
    mRet cand4 = checkIndex(part, n1, n2, astart, bstart, to, bm2 - 1, res);
    cand4.valid = cand4.valid && bm2Min1Valid;

    ret = cand1;
    if (cand2.valid && (compare(part, cand2, ret, res) || !ret.valid)) {
        ret = cand2;
    }
    if (cand3.valid && (compare(part, cand3, ret, res) || !ret.valid)) {
        ret = cand3;
    }
    if (cand4.valid && (compare(part, cand4, ret, res) || !ret.valid)) {
        ret = cand4;
    }
    mRet AnMin1 = getM(part, astart + n1 - 1, res);
    mRet BtoMinN = getM(part, bstart + to - n1, res);
    mRet BnMin1 = getM(part, bstart + n2 - 1, res);
    mRet AtoMinN = getM(part, astart + to - n2, res);
    if (targetOffset >= n1 && compare(part, AnMin1, BtoMinN, res) && BtoMinN.valid) {
        ret = BtoMinN;
    }
    if (targetOffset >= n2 && compare(part, BnMin1, AtoMinN, res) && AtoMinN.valid) {
        ret = AtoMinN;
    }

    if (i >= maxBin - 1) {
        ret = error;
    }
    return ret;
}

struct mcData {
    int pass;
    int n;
    bool overflow;
    int index;
    int base;
    int astart;
    int bstart;
    int targetOffset;
};

mcData getMCData(int part,mPartitionData pd) {
    mcData ret;
    ret.pass = max(0, pd.partitionIndex - 1);
    ret.n = (1 << ret.pass);
    ret.overflow = 2 * ret.n > pd.particlesPerPartition || pd.particlesPerPartition % ret.n != 0;
    ret.index = pd.index - pd.particlesPerPartition;
    ret.base = ret.index - ret.index % (2 * ret.n);
    ret.astart = ret.base;
    ret.bstart = ret.base + ret.n;
    ret.targetOffset = ret.index - ret.base;
    return ret;
}

vec4 mergeSort(in vec2 fragCoord) {
    vec4 fragColor = vec4(0.0);
    vec2 res = maxRes;
    mPartitionData pd = getPartitionData(sortedBuffer, fragCoord, res);

    //fragColor.x = texelFetch(sortedBuffer, ivec2(fragCoord), 0).x;

    bool overflow = false;
    for (int part = 0; part < vec4Count; part++) {
        mcData ret = getMCData(PART, pd);
    	overflow = overflow || ret.overflow;
        fragColor[PART] = binarySearchForMergeSlim(
            PART, ret.targetOffset, ret.n, ret.n,
            res, ret.astart, ret.bstart).vi[PART];
    }
    if (pd.partitionIndex + 1 < pd.partitionCount) {
        fragColor.x += float(pd.particlesPerPartition);
    }

    if (overflow) {
        //fragColor.x = pd.futureParticle.x;
        fragColor.x = 0.0;
        return fragColor;
    }

    if (pd.partitionIndex == 0) {
        fragColor.x = float(pd.index);
        fragColor.x += float(pd.particlesPerPartition);
    }

    return fragColor;
}





// BEGIN PARTICLES

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
    float G = 5.0e-1;
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

vec4 computeParticles(in vec2 fragCoord )
{
    vec4 fragColor = vec4(0.0);
    vec2 res = maxRes;
    mPartitionData pd = getPartitionData(particleBuffer, fragCoord, res);

    if (iFrame == 0) {
        fragColor = vec4(0.0);

        vec2 particle = vec2(0.0);
        if (pd.partitionIndex == 0) {
            // position
            vec2 fc = vec2(fromLinear(pd.index, res));
            vec4 data = hash42(fc);
            particle = transformPos(data.xy);
        } else {
            // velocity
            vec2 fc = vec2(fromLinear(pd.futureIndex, res));
            vec4 data = hash42(fc);

            vec2 pos = transformPos(data.xy);
            vec2 vel = 10.0 * (data.zw - 0.5) / res;
            float maxSpeed = 1.0;
            vel = length(vel) > maxSpeed ? maxSpeed * vel / length(vel) : vel;
            vel = vec2(0.0);
            vec2 oldPos = pos - vel;
            particle = oldPos;
        }

        if (pd.overflow) {
            particle = vec2(0.0);
        }

        fragColor.yz = particle;

        return fragColor;
    }

    vec4 particle1 = vec4(0.0);
    particle1.xy = getPosition(particleBuffer, pd.index, res);
    particle1.zw = getPosition(particleBuffer, pd.pastIndex, res);

    const int k = 16;
    const int k2 = 4;
    int w = int(sqrt(float(k)));
    vec2 a1 = vec2(0.0);
    vec2 a2 = vec2(0.0);
    int torusCount = int(pow(2.0, float(int(iTime / 4.0) % 10)));
    int particlesPerTorus = pd.particlesPerPartition / torusCount;
    int wp = int(sqrt(float(particlesPerTorus)));
    int torus = pd.index / particlesPerTorus;
    for (int i = 0; i < k; i++) {
        {
            int index = pd.index % particlesPerTorus;
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
            int j = toLinear(fc, vec2(wp)) + pd.index - index;
            vec2 p2 = getPosition(particleBuffer, j, res);
            a1 += getSpring(res, particle1, p2.xy) / float(w);
        }
        for (int i2 = 0; i2 < k2; i2++) {
            int w = int(sqrt(float(k)));
            int index = pd.index % particlesPerTorus;
            int j =
                int(float(particlesPerTorus) *
                    hash(uvec2(fragCoord + float(i * k + i2) * vec2(13.0, 29.0) * vec2(iFrame))));
            j += pd.index - index;
            vec2 p2 = getPosition(particleBuffer, j, res);
            a1 += getGravity(res, particle1, p2.xy) / float(w * k2);
        }
    }

    vec2 updatedParticle = updateParticle(particle1, a1).xy;

    fragColor.yz = pd.partitionIndex == 0 ? updatedParticle.xy : extractPosition(pd.futureParticle);
    fragColor.yz = pd.overflow ? vec2(0.0) : fragColor.yz;

    return fragColor;
}

// END PARTICLES


float computeZOrder(in vec2 fragCoord) {
    vec2 res = realRes;
    vec2 pres = getRes(res);
    vec2 fc = fragCoord / res * pres;
    int index = toIndexFull(fc, pres);
    return float(index);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    /*
    int maxLinear = toLinear(res - 1.0, res);
    if (frag
	*/
    if (iFrame == 0) {
        fragColor.xyz = vec3(0.0);
        fragColor.w = computeZOrder(fragCoord);
    } else {
        fragColor.w = texelFetch(mortonBuffer, ivec2(fragCoord), 0).w;
    }
    vec2 res = maxRes;
    if (fragCoord.x >= res.x || fragCoord.y >= res.y) {
        //discard;
        return;
    }
    fragColor.x = mergeSort(fragCoord).x;
    fragColor.yz = computeParticles(fragCoord).yz;
}

