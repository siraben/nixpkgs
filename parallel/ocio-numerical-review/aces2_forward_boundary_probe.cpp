#include <OpenColorIO/OpenColorIO.h>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>
namespace OCIO = OCIO_NAMESPACE;
using Pixel = std::array<float, 4>;
static_assert(sizeof(float)==4 && sizeof(Pixel)==16, "packed binary32 RGBA required");
float fromWord(std::uint32_t w) { float f; std::memcpy(&f,&w,4); return f; }
std::uint32_t word(float f) { std::uint32_t w; std::memcpy(&w,&f,4); return w; }
void emit(const char * label, const Pixel & p)
{
    std::cout << label;
    for (float f : p)
        std::cout << " value=" << std::setprecision(17) << static_cast<double>(f)
                  << "/0x" << std::hex << word(f) << std::dec
                  << "/finite=" << std::isfinite(f);
    std::cout << '\n';
}
Pixel runCPU(const OCIO::ConstCPUProcessorRcPtr & cpu, Pixel input)
{
    Pixel output{};
    OCIO::PackedImageDesc in(input.data(),1,1,4), out(output.data(),1,1,4);
    cpu->apply(in,out);
    return output;
}
int main(int argc, char ** argv)
{
    try
    {
        if (argc!=3) throw std::runtime_error("profile and input case required");
        const std::string profile=argv[1], inputCase=argv[2];
        if (profile!="rec709" && profile!="p3") throw std::runtime_error("unknown profile");
        std::array<std::uint32_t,3> words{};
        if (inputCase=="clang-inverse") words={{0x42ffffd0u,0x42ffffcfu,0x42ffffd0u}};
        else if(inputCase=="reference-inverse") words={{0x42ffffd2u,0x42ffffccu,0x42ffffd1u}};
        else if(inputCase=="ideal") words={{0x43000000u,0x43000000u,0x43000000u}};
        else throw std::runtime_error("unknown input case");
        const Pixel input{{fromWord(words[0]),fromWord(words[1]),fromWord(words[2]),0.f}};
        std::cout << "probe=public_forward_boundary_v1 profile=" << profile
                  << " input_case=" << inputCase << " library=" << OCIO::GetVersion()
                  << " pointer_bits=" << sizeof(void*)*8 << " optimization=NONE\n";
        emit("input",input);
        auto builtin=OCIO::BuiltinTransform::Create();
        builtin->setStyle(profile=="rec709"
          ? "ACES-OUTPUT - ACES2065-1_to_CIE-XYZ-D65 - SDR-100nit-REC709_2.0"
          : "ACES-OUTPUT - ACES2065-1_to_CIE-XYZ-D65 - SDR-100nit-P3-D65_2.0");
        auto config=OCIO::Config::CreateRaw();
        auto processor=config->getProcessor(builtin);
        emit("full_builtin",runCPU(processor->getOptimizedCPUProcessor(OCIO::OPTIMIZATION_NONE),input));
        auto expanded=processor->createGroupTransform();
        auto prefix=OCIO::GroupTransform::Create();
        for(int i=0;i<expanded->getNumTransforms();++i)
        {
            auto node=expanded->getTransform(i);
            std::cout << "op=" << i << " type=" << static_cast<int>(node->getTransformType())
                      << " direction=" << static_cast<int>(node->getDirection()) << '\n';
            if(node->getTransformType()==OCIO::TRANSFORM_TYPE_FIXED_FUNCTION)
            {
                auto ff=std::dynamic_pointer_cast<OCIO::FixedFunctionTransform>(node);
                std::vector<double> params(ff->getNumParams());
                ff->getParams(params.data());
                std::cout << "fixed_style=" << static_cast<int>(ff->getStyle());
                for(double v:params) std::cout << " param=" << std::setprecision(17) << v;
                std::cout << '\n';
            }
            prefix->appendTransform(node);
            emit("prefix_output",runCPU(config->getProcessor(prefix)->getOptimizedCPUProcessor(OCIO::OPTIMIZATION_NONE),input));
        }
        std::cout << "measurement_complete=true correctness_verdict=not_asserted\n";
        return 0;
    }
    catch(const std::exception & e) { std::cerr << "probe_exception=" << e.what() << '\n'; return 2; }
}
