#version 300 es
precision highp float;
precision highp int;

#define mortonBuffer iChannel0
#define sortedBuffer iChannel0
#define particleBuffer iChannel0
#define pixelNearestBuffer iChannel1

//#define maxRes min(vec2(800.0, 450.0), iResolution.xy)
#define maxRes min(vec2(512.0, 512.0), iResolution.xy)
//#define maxRes min(vec2(1024.0, 512.0), iResolution.xy)
//#define maxRes min(vec2(128.0, 128.0), iResolution.xy)
//#define maxRes min(vec2(512.0, 256.0), iResolution.xy)
//#define maxRes min(vec2(iResolution.x, 256.0), iResolution.xy)
//#define maxRes min(vec2(512.0, iResolution.y), iResolution.xy)
//#define maxRes iResolution.xy
#define realRes iResolution.xy
#define powerOfTwoRes vec2(2048.0, 2048.0)
//#define realRes maxRes
//#define maxRes iResolution.xy

// Try this true for more Matrix fun :)
const bool justSentinels = true;

// number of particles will be 2^magicNumberDoNotChange = 64k
// I haven't figured out why it seems to work only when this number is 16
const int magicNumberDoNotChange = 16;
const int MAX_ITER = 12;
const int maxBin = 32;
const int vec4Count = 1;
#define PART part
const float M_PI = 3.14159265358979323846264338327950288;

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

int getMaxPasses2(vec2 res) {
    return int(ceil(log2(res.x * res.y)));
}

struct mPartitionData {
    int partitionCount;
    int maxIndex;
    int particlesPerPartition;
    int index;
    int partitionIndex;
    int offset;
    int pastIndex;
    int futureIndex;
    ivec2 futureCoord;
    vec4 futureParticle;
    bool overflow;
};

vec2 extractPosition(vec4 data) {
    return data.yz;
}

// BEGIN QUALITY HASHES

uint baseHash(uvec2 p)
{
    p = 1103515245U*((p >> 1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    return h32^(h32 >> 16);
}


//---------------------2D input---------------------

float hash12(uvec2 x)
{
    uint n = baseHash(x);
    return float(n)*(1.0/float(0xffffffffU));
}

vec2 hash22(uvec2 x)
{
    uint n = baseHash(x);
    uvec2 rz = uvec2(n, n*48271U);
    return vec2(rz.xy & uvec2(0x7fffffffU))/float(0x7fffffff);
}

vec3 hash32(uvec2 x)
{
    uint n = baseHash(x);
    uvec3 rz = uvec3(n, n*16807U, n*48271U);
    return vec3(rz & uvec3(0x7fffffffU))/float(0x7fffffff);
}

vec4 hash42(uvec2 x)
{
    uint n = baseHash(x);
    uvec4 rz = uvec4(n, n*16807U, n*48271U, n*69621U); //see: http://random.mat.sbg.ac.at/results/karl/server/node4.html
    return vec4(rz & uvec4(0x7fffffffU))/float(0x7fffffff);
}

//--------------------------------------------------


//Example taking an arbitrary float value as input
/*
	This is only possible since the hash quality is high enough so that
	floored float input doesn't break the process when the raw bits are used
*/
vec4 hash42(vec2 x)
{
    uint n = baseHash(floatBitsToUint(x));
    uvec4 rz = uvec4(n, n*16807U, n*48271U, n*69621U);
    return vec4(rz & uvec4(0x7fffffffU))/float(0x7fffffff);
}

// END QUALITY HASHES


float hash( uvec2 x )
{
    uvec2 q = 1103515245U * ( (x>>1U) ^ (x.yx   ) );
    uint  n = 1103515245U * ( (q.x  ) ^ (q.y>>3U) );
    return float(n) * (1.0/float(0xffffffffU));
}

vec2 getRes(vec2 res) {
    //return vec2(exp2(ceil(log2(max(res.x, res.y)))));
    return powerOfTwoRes;
}

int toIndexCol(in vec2 fragCoord, in vec2 resolution, inout vec3 col) {
    int xl = int(fragCoord.x);
    int yl = int(fragCoord.y);
    ivec2 res = ivec2(resolution);
    int div2 = 1;
    /*
    for (int i = 0; i < MAX_ITER; i++) {
        res /= 2;
        div2 *= 2;
        if (res.x == 0 && res.y == 0) break;
    }
    res = ivec2(div2);
	*/
    int index = 0;
    int div = 1;
    div2 = 1;
    bool colorDone = false;
    for (int i = 0; i < MAX_ITER; i++) {
        ivec2 rest = res % 2;
        res /= 2;
        if (res.x == 0 && res.y == 0) break;
        div *= 4;
        div2 *= 2;
        int x = int(xl >= res.x);
        int y = int(yl >= res.y);
        xl -= x * res.x;
        yl -= y * res.y;
        //res += x * rest.x;
        //res += y * rest.y;
        int thisIndex = y * 2 + x;
        index = index * 4 + thisIndex;

        if (!colorDone) {
            vec2 uv = vec2(xl, yl) / vec2(res);
            vec2 center = vec2(0.5);
            float d = distance(uv, center);
            float r = float(d < 0.25);
            bool border = d > 0.25 - 0.02 / float(div2) && d < 0.25;
            if (border) {
                colorDone = true;
            } else {
            	col = vec3(float(int(col) ^ int(r)));
            }
        }
    }
    //return res.x * res.y - index - 1;
    return index;
}

int toIndexFull(in vec2 fragCoord, in vec2 resolution) {
    vec3 col = vec3(0.0);
    int index = toIndexCol(fragCoord, resolution, col);
    //index += 1;
    return index;
}

ivec2 fromIndexFull(in int index, in vec2 resolution) {
    //index -= 1;
    ivec2 fc = ivec2(0);
    int div = 1;
    ivec2 div2 = ivec2(1);
    ivec2 res = ivec2(resolution);
    //index = res.x * res.y - index - 1;
    for (int i = 0; i < MAX_ITER; i++) {
        res /= 2;
        //int rx = res.x % 2 == 0 ? 2 : 1;
        //int ry = res.y % 2 == 0 ? 2 : 1;

        int thisIndex = index % 4;
        fc.x += div2.x * (thisIndex % 2);
        fc.y += div2.y * (thisIndex / 2);
        index = index / 4;

        div2 *= 2;
        if (index == 0) break;
    }
    return fc;
}

ivec2 fromLinear(in int index, in vec2 resolution) {
    //index -= 1;
    return ivec2(index % int(resolution.x), index / int(resolution.x));
}

int toLinear(in vec2 fragCoord, in vec2 resolution) {
    int index = int(fragCoord.x) + int(fragCoord.y) * int(resolution.x);
    //index += 1;
    return index;
}

#define toIndex(a) toIndex2(mortonBuffer, a, realRes)
int toIndex2(in sampler2D channel, in vec2 fragCoord, in vec2 res) {
    ivec2 fc = ivec2(fragCoord * res);
    vec4 index = texelFetch(channel, fc, 0);
    return int(index.w);
}

vec2 getPosition(sampler2D channel, int index, vec2 res) {
    ivec2 fc = fromLinear(index, res);
    vec4 data = texelFetch(channel, fc, 0);
    return fract(extractPosition(data));
}

int maxLinear(vec2 res) {
    return int(exp2(floor(log2(float(toLinear(res - 1.0, res))))));
}

bool isLinearValid(in int index, vec2 iResolution) {
    vec2 res = iResolution.xy;
    //return true;
	return index < maxLinear(iResolution);
}

bool isValid(in vec2 fragCoord, vec2 iResolution) {
    vec2 res = iResolution.xy;
    return isLinearValid(toLinear(fragCoord, res), iResolution);
}

#define getPartitionData(a, b, c) getPartitionData2(a, b, c, realRes)
mPartitionData getPartitionData2(sampler2D channel, vec2 fragCoord, vec2 res, vec2 rRes) {
    //fragCoord = fragCoord / rRes * res;
    mPartitionData mRet;
    //int maxPasses = getMaxPasses(res);
    //mRet.partitionCount = int(exp2(ceil(log2(float(maxPasses)))));
    mRet.partitionCount = magicNumberDoNotChange;
    //mRet.maxIndex = toLinear(res - 1.0, res);
    mRet.maxIndex = maxLinear(res);
    mRet.particlesPerPartition = mRet.maxIndex / mRet.partitionCount;
    mRet.index = toLinear(fragCoord, res);
    mRet.partitionIndex = mRet.index / mRet.particlesPerPartition;
    mRet.offset = mRet.index % mRet.particlesPerPartition;
    mRet.futureIndex = mRet.index - mRet.particlesPerPartition;
    mRet.futureCoord = fromLinear(mRet.futureIndex, res);
    mRet.futureParticle = texelFetch(channel, mRet.futureCoord, 0);
    mRet.pastIndex = mRet.index + mRet.particlesPerPartition;
    mRet.overflow = mRet.index >= mRet.maxIndex;

    //(mRet.partitionIndex - 1) * mRet.particlesPerPartition + mRet.offset;


    return mRet;
}

int getMaxPartition(mPartitionData pd) {
    // TODO: optimize / hardcode
    int k = 0;
    for (int i = 0; i <= pd.partitionCount; i++) {
        int n = 1 << i;
		if (2 * n > pd.particlesPerPartition || pd.particlesPerPartition % n != 0) break;
        k = i;
    }
    return k + 1;
    //return k;
}

struct mRet {
    int dIndex;
    int Am;
    vec4 vi;
    vec4 v;
    vec2 pos;
    bool valid;
};

#define getMD(a, b, c) getMD2(particleBuffer, mortonBuffer, a, b, c, realRes)
mRet getMD2(sampler2D channel, sampler2D mchannel, int part, int m, vec2 res, vec2 rRes) {
    vec2 fc = vec2(fromLinear(m, res));
    vec4 v = texelFetch(channel, ivec2(fc), 0);
    vec2 pos = extractPosition(v);
    int Am = toIndex2(mchannel, pos, rRes);
    int maxIndex = toLinear(res - 1.0, res);
    bool valid = m >= 0 && m <= maxIndex && isLinearValid(m, res);
    //valid = true;
    return mRet(m, Am, vec4(0.0), v, pos, valid);
}

#define getM(a, b, c) getM2(sortedBuffer, particleBuffer, mortonBuffer, a, b, c, realRes)
mRet getM2(sampler2D channel, sampler2D pchannel, sampler2D mchannel, int part, int m, vec2 res, vec2 rRes) {
    vec2 fc = vec2(fromLinear(m, res));
    vec4 v = texelFetch(channel, ivec2(fc), 0);
    mRet ret2 = getMD2(pchannel, mchannel, part, int(v[part]), res, rRes);
    int maxIndex = toLinear(res - 1.0, res);
    bool valid = m >= 0 && m <= maxIndex && isLinearValid(m, res);
    //valid = true;
    return mRet(int(v[part]), ret2.Am, v, ret2.v, ret2.pos, valid && ret2.valid);
}
