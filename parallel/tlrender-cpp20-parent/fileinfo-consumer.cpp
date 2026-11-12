#include <tlCore/FileInfo.h>
#include <sys/types.h>
#include <cassert>
#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>
#ifdef NDEBUG
#error Assertions must be enabled
#endif
int main(int argc,char**argv)
{
    assert(argc==3);
    assert(sizeof(void*)==4 && sizeof(time_t)==4);
    // tlCore's public FileInfo interface does not expose off_t or dirent.
    assert(sizeof(off_t)==4);
    const std::string directory=argv[1];
    const auto expected=std::strtoull(argv[2],nullptr,10);
    tl::file::FileInfo info(tl::file::Path(directory+"/config.ocio"));
    assert(info.getType()==tl::file::Type::File && info.getSize()==expected);
    tl::file::ListOptions options; options.sequence=false;
    std::vector<tl::file::FileInfo> entries;
    tl::file::list(directory,entries,options);
    bool config=false,subdir=false;
    for(const auto& entry:entries)
    {
        const auto name=entry.getPath().get();
        if(name.find("config.ocio")!=std::string::npos)
            config=entry.getType()==tl::file::Type::File && entry.getSize()==expected;
        if(name.find("shot1")!=std::string::npos)
            subdir=entry.getType()==tl::file::Type::Directory;
    }
    assert(config && subdir);
    std::cout << "PASS: installed tlCore high-inode stat/directory API, narrow caller off_t="
              << sizeof(off_t) << " time_t=" << sizeof(time_t) << " entries=" << entries.size() << '\n';
}
