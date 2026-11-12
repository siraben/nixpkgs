#include <OpenColorIO/OpenColorIO.h>
#include <array>
#include <cfenv>
#include <cfloat>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <limits>
#include <locale>

namespace OCIO = OCIO_NAMESPACE;
static_assert(sizeof(float) == sizeof(std::uint32_t), "32-bit float required");
static_assert(std::numeric_limits<float>::is_iec559 &&
              std::numeric_limits<float>::digits == 24, "IEEE binary32 required");

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

void emitFloat(const char * name, float value)
{
    const std::uint32_t word = toWord(value);
    const double stored = static_cast<double>(fromWord(word));
    std::cout << ' ' << name << "={dec:" << std::defaultfloat
              << std::setprecision(17) << stored << ",hex:"
              << std::hexfloat << stored << std::defaultfloat << ",bits:0x"
              << std::hex << std::setw(8) << std::setfill('0') << word
              << std::dec << std::setfill(' ') << '}';
}

using Pixel = std::array<float, 4>;
using Image = std::array<Pixel, 4>;
static_assert(sizeof(Pixel) == 4 * sizeof(float), "packed RGBA required");

void emitPixel(const char * stage, const Pixel & pixel)
{
    std::cout << "stage=" << stage;
    const char * channels[] = {"r", "g", "b", "a"};
    for (unsigned c = 0; c < 4; ++c) emitFloat(channels[c], pixel[c]);
    std::cout << '\n';
}

int main()
{
    try
    {
        std::cout.imbue(std::locale::classic());
        const char * display = "DISPLAY - CIE-XYZ-D65_to_ST2084-P3-D65";
        const char * view =
            "ACES-OUTPUT - ACES2065-1_to_CIE-XYZ-D65 - HDR-4000nit-P3-D65_2.0";
        std::cout << "probe=aces2_public_v1 header_version=" << OCIO_VERSION_STR
                  << " library_version=" << OCIO::GetVersion()
                  << " library_version_hex=0x" << std::hex << OCIO::GetVersionHex()
                  << std::dec << " compiler=" << __VERSION__
                  << " pointer_bits=" << 8 * sizeof(void *)
                  << " long_double_bytes=" << sizeof(long double)
                  << " FLT_EVAL_METHOD=" << FLT_EVAL_METHOD
                  << " fe_round=" << std::fegetround()
                  << " FE_TONEAREST=" << FE_TONEAREST << '\n';
        std::cout << "display=\"" << display << "\"\nview=\"" << view << "\"\n"
                  << "optimization=OPTIMIZATION_NONE config=CreateRaw"
                  << " peak_nits=4000 limiting=P3-D65 encoding=P3-D65"
                  << " linear_scale=1 scale_white=false alpha=0 grid_edge=7\n";
        std::cout << "parameters";
        emitFloat("grid_scale", fromWord(0x3f661134u));
        const float tolerance = fromWord(0x3be56042u); // Original 0.007f.
        emitFloat("tolerance", tolerance);
        std::cout << " comparator=stored_float_abs_error<=stored_float_tolerance\n";

        const std::uint32_t z = 0x00000000u, s = 0x3f661134u;
        const std::array<std::array<std::uint32_t, 4>, 4> words = {{
            {{z, s, s, z}}, // cyan, original float-array offset 1344
            {{z, z, z, z}}, // black, offset 0
            {{s, s, z, z}}, // yellow, offset 192
            {{s, s, s, z}}  // white, offset 1368
        }};
        const char * names[] = {"cyan", "black", "yellow", "white"};
        const unsigned offsets[] = {1344, 0, 192, 1368};
        Image input{};
        for (unsigned p = 0; p < input.size(); ++p)
            for (unsigned c = 0; c < 4; ++c)
                input[p][c] = fromWord(words[p][c]);

        auto displayForward = OCIO::BuiltinTransform::Create();
        displayForward->setStyle(display);
        displayForward->validate();
        auto displayInverse = displayForward->createEditableCopy();
        displayInverse->setDirection(OCIO::TRANSFORM_DIR_INVERSE);
        auto viewForward = OCIO::BuiltinTransform::Create();
        viewForward->setStyle(view);
        viewForward->validate();
        auto viewInverse = viewForward->createEditableCopy();
        viewInverse->setDirection(OCIO::TRANSFORM_DIR_INVERSE);
        const std::array<OCIO::TransformRcPtr, 4> transforms = {{
            displayInverse, viewInverse, viewForward, displayForward
        }};
        const char * stages[] = {
            "after_display_inverse", "after_view_inverse",
            "after_view_forward", "after_display_forward"
        };
        auto config = OCIO::Config::CreateRaw();
        auto group = OCIO::GroupTransform::Create();
        std::array<Image, 4> outputs{};
        for (unsigned stage = 0; stage < transforms.size(); ++stage)
        {
            group->appendTransform(transforms[stage]);
            const auto processor = config->getProcessor(group);
            const auto cpu = processor->getOptimizedCPUProcessor(OCIO::OPTIMIZATION_NONE);
            OCIO::PackedImageDesc inDesc(input.data(), input.size(), 1, 4);
            OCIO::PackedImageDesc outDesc(outputs[stage].data(), input.size(), 1, 4);
            cpu->apply(inDesc, outDesc);
            std::cout << "prefix=" << stages[stage]
                      << " processor_cache_id=\"" << processor->getCacheID() << "\"\n";
        }

        bool allPass = true;
        const char * channels[] = {"r", "g", "b"};
        for (unsigned p = 0; p < input.size(); ++p)
        {
            std::cout << "sample=" << names[p] << " original_rgba_offset=" << offsets[p]
                      << " difficult=false\n";
            emitPixel("input", input[p]);
            for (unsigned stage = 0; stage < outputs.size(); ++stage)
                emitPixel(stages[stage], outputs[stage][p]);
            bool samplePass = true;
            for (unsigned c = 0; c < 3; ++c)
            {
                const float actual = outputs.back()[p][c];
                const float expected = input[p][c];
                // For these samples max(abs(expected), 1) is exactly 1.
                // Binary64 subtraction is exact for the nearby finite float values;
                // round/store the resulting error as binary32 before comparing.
                const float error = fromWord(toWord(static_cast<float>(std::fabs(
                    static_cast<double>(actual) - static_cast<double>(expected)))));
                const bool pass = std::isfinite(actual) &&
                    static_cast<double>(error) <= static_cast<double>(tolerance);
                std::cout << "channel=" << channels[c];
                emitFloat("absolute_error", error);
                std::cout << " pass=" << (pass ? "true" : "false") << '\n';
                samplePass = samplePass && pass;
            }
            std::cout << "sample_pass=" << (samplePass ? "true" : "false") << '\n';
            allPass = allPass && samplePass;
        }
        std::cout << "all_pass=" << (allPass ? "true" : "false") << '\n';
        return allPass ? 0 : 1;
    }
    catch (const std::exception & error)
    {
        std::cerr << "probe_exception=" << error.what() << '\n';
        return 2;
    }
}
