import router from '@ohos.router';
import http from '@ohos.net.http';
import { HeaderFrame } from '../Common/HeaderFrame';
import { HeaderIcon } from '../Common/HeaderIcon';
import { getTheme } from '../Common/Theme';
import { WindowFrame } from '../Common/WindowFrame';
import hilog from '@ohos.hilog';
import resourceManager from '@ohos.resourceManager';
import { server } from '../Server';


@Styles function styleSolidCard() {
  .backgroundColor(getTheme().colorScheme.surface)
  .borderRadius('10vp')
}

@Extend(Text) function styleHeader() {
  .fontColor(getTheme().colorScheme.onSurface)
  .fontSize('20fp')
  .fontWeight(FontWeight.Medium)
}

type BookItem = {
  id: string;
  cover: PixelMap | Resource | string;
  name: string;
  desc: string;
  wordCount: number;
}

type BookType = {
  name: string
  item: BookItem[]
}




@Entry
@Component
struct BookSelect {
  @State
  currTypeSelectTabIndex: number = 0;
  @State
  books: BookType[] = []

  @Builder
  headerLeftSlot() {
    HeaderIcon({ src: $r('app.media.icon_arrow_back') })
      .onClick(event => {
        router.back()
      })
  }

  @Builder
  headerRightSlot() {
  }

  @Builder
  header() {
    HeaderFrame({
      title: '词库',
      leftSlot: this.headerLeftSlot,
      rightSlot: this.headerRightSlot
    })
  }

  @Builder
  typeSelectTabBuilder(index: number, text: string) {
    Column({ space: '2vp' }) {
      Text(text)
        .fontSize('16vp')
        .fontWeight(FontWeight.Medium)
        .fontColor(
            index == this.currTypeSelectTabIndex
            ? getTheme().colorScheme.onSurface
            : getTheme().colorScheme.onSurfaceLow
        )
      Line({ width: '20vp', height: '3vp' })
        .startPoint(['0vp', '1.5vp'])
        .endPoint(['20vp', '1.5vp'])
        .stroke(
            index == this.currTypeSelectTabIndex
            ? getTheme().colorScheme.primary
            : Color.Transparent
        )
        .strokeWidth('3dp')
    }
    .padding({ left: '8vp', right: '8vp' })
  }

  @Builder
  bookItemBuilder(item: BookItem) {
    Row({ space: '12vp' }) {
      Image(item.cover)
        .height('100%')
        .borderRadius('8vp')
      Column() {
        Column({ space: '4vp' }) {
          Text(item.name)
            .fontSize('18fp')
            .fontWeight(FontWeight.Medium)
            .fontColor(getTheme().colorScheme.onSurface)
          Text(item.desc)
            .fontSize('14fp')
            .fontColor(getTheme().colorScheme.onSurfaceLow)
        }
        .alignItems(HorizontalAlign.Start)

        Text(`${item.wordCount}词`)
          .fontSize('15fp')
          .fontColor(getTheme().colorScheme.onSurfaceLow)
      }
      .padding('6vp')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .height('96vp')
    .padding({left:'20vp', right:'20vp'})
  }

  @Builder
  content() {
    Column() {
      Search()
        .margin({ left: '20vp', right: '20vp' })
      Tabs({ barPosition: BarPosition.Start }) {

        ForEach(this.books, (elem: BookType, index) => {
          TabContent() {
            Scroll() {
              Column({space:'30vp'}){
                ForEach(elem.item, (elem: BookItem, index) => {
                  this.bookItemBuilder(elem);
                })
              }
            }
            .size({ width: '100%', height: '100%' })
            .align(Alignment.Top)
          }
          .tabBar(this.typeSelectTabBuilder(index, elem.name))
        })
      }
      .barMode(BarMode.Scrollable)
      .onChange(index => this.currTypeSelectTabIndex = index);
    }
  }

  build() {
    Column() {
      WindowFrame({
        content: this.content.bind(this),
        header: this.header.bind(this)
      })

    }
  }

  parseBookList(obj:Object){
    type listItem = {
      id:string;
      name:string;
      desc:string;
      word_count:number;
      type:string;
      tag:string[];
    }
    if(!(obj['list'] instanceof Array))
      return;
    let tmp:Record<string, Array<listItem>> = {};
    (obj['list'] as Array<listItem>).forEach(item => {
      if(tmp[item.type] === undefined)
        tmp[item.type] = [];
      tmp[item.type].push(item);
    })

    for(const key in tmp){
      let tp:BookType = {name:key, item:[]};
      tmp[key].forEach(elem => {
        tp.item.push({
          id:elem.id,
          name:elem.name,
          desc: elem.desc,
          wordCount:elem.word_count,
          cover:`${server.ip}/books/${elem.id}/cover.png`
        });
      })
      this.books.push(tp);
    }
  }

  requestBookList(){
    let httpRequest = http.createHttp();
    console.info("HTTP_REQ", "About to req", server.ip + 'book_list.json')
    httpRequest.request(
      `${server.ip}/book_list.json`,
      { method: http.RequestMethod.GET },
      (err, data: http.HttpResponse) => {
        if (err) {
          console.error("HTTP_REQ", "ERROR:", err.message);
          return
        }
        let rawResponse = data.result.toString();
        let response = JSON.parse(rawResponse)
        this.parseBookList(response);
      }
    )
  }

  aboutToAppear() {
    this.requestBookList();
  }
}