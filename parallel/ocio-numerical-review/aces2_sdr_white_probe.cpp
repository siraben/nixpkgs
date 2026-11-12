#include <OpenColorIO/OpenColorIO.h>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>

namespace OCIO = OCIO_NAMESPACE;
using Pixel = std::array<float, 4>;
static_assert(sizeof(float) == sizeof(std::uint32_t));
float fromWord(std::uint32_t word)
{
    float value;
    std::memcpy(&value, &word, sizeof(value));
    return value;
}
std::uint32_t toWord(float value)
{
    std::uint32_t word;
    std::memcpy(&word, &value, sizeof(word));
    return word;
}
void emit(const char * stage, const Pixel & pixel)
{
    std::cout << "stage=" << stage;
    for (float channel : pixel)
        std::cout << " value=" << std::setprecision(17) << static_cast<double>(channel)
                  << "/0x" << std::hex << std::setw(8) << std::setfill('0')
                  << toWord(channel) << std::dec << std::setfill(' ');
    std::cout << '\n';
}
int main(int argc, char ** argv)
{
    try
    {
        if (argc != 2) throw std::runtime_error("profile required: rec709 or p3");
        const bool rec709 = std::string(argv[1]) == "rec709";
        if (!rec709 && std::string(argv[1]) != "p3")
            throw std::runtime_error("unknown profile");
        const char * display = rec709 ? "DISPLAY - CIE-XYZ-D65_to_REC.1886-REC.709"
                                     : "DISPLAY - CIE-XYZ-D65_to_DisplayP3";
        const char * view = rec709
            ? "ACES-OUTPUT - ACES2065-1_to_CIE-XYZ-D65 - SDR-100nit-REC709_2.0"
            : "ACES-OUTPUT - ACES2065-1_to_CIE-XYZ-D65 - SDR-100nit-P3-D65_2.0";
        // Original binary32 0.004f / 0.001f tolerances, no difficult exception.
        const float tolerance = fromWord(rec709 ? 0x3b83126fu : 0x3a83126fu);
        const Pixel input{{fromWord(0x3f800000u), fromWord(0x3f800000u),
                           fromWord(0x3f800000u), fromWord(0)}};
        std::cout << "probe=sdr_white_public_v1 profile=" << argv[1]
                  << " original_rgba_offset=1368 difficult=false pointer_bits="
                  << sizeof(void *) * 8 << " header=" << OCIO_VERSION_STR
                  << " library=" << OCIO::GetVersion() << " tolerance="
                  << std::setprecision(17) << static_cast<double>(tolerance)
                  << " optimization=OPTIMIZATION_NONE\ndisplay=" << display
                  << "\nview=" << view << '\n';
        emit("input", input);
        auto df = OCIO::BuiltinTransform::Create(); df->setStyle(display); df->validate();
        auto di = df->createEditableCopy(); di->setDirection(OCIO::TRANSFORM_DIR_INVERSE);
        auto vf = OCIO::BuiltinTransform::Create(); vf->setStyle(view); vf->validate();
        auto vi = vf->createEditableCopy(); vi->setDirection(OCIO::TRANSFORM_DIR_INVERSE);
        const std::array<OCIO::TransformRcPtr, 4> transforms{{di, vi, vf, df}};
        const char * stages[] = {"display_inverse", "view_inverse", "view_forward", "display_forward"};
        auto config = OCIO::Config::CreateRaw();
        auto group = OCIO::GroupTransform::Create();
        Pixel output{};
        for (unsigned stage = 0; stage < transforms.size(); ++stage)
        {
            group->appendTransform(transforms[stage]);
            const auto cpu = config->getProcessor(group)->getOptimizedCPUProcessor(OCIO::OPTIMIZATION_NONE);
            Pixel source = input;
            OCIO::PackedImageDesc inDesc(source.data(), 1, 1, 4);
            OCIO::PackedImageDesc outDesc(output.data(), 1, 1, 4);
            cpu->apply(inDesc, outDesc);
            emit(stages[stage], output);
        }
        bool pass = true;
        for (unsigned channel = 0; channel < 3; ++channel)
        {
            const float error = fromWord(toWord(static_cast<float>(std::fabs(
                static_cast<double>(output[channel]) - static_cast<double>(input[channel])))));
            pass = pass && std::isfinite(output[channel])
                   && static_cast<double>(error) <= static_cast<double>(tolerance);
        }
        std::cout << "sample_pass=" << (pass ? "true" : "false") << '\n';
        return pass ? 0 : 1;
    }
    catch (const std::exception & error)
    {
        std::cerr << "probe_exception=" << error.what() << '\n';
        return 2;
    }
}
