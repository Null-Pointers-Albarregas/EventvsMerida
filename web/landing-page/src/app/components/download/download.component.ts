import { Component } from '@angular/core';
import { RevealDirective } from '../../directives/reveal.directive';

@Component({
  selector: 'app-download',
  standalone: true,
  imports: [RevealDirective],
  templateUrl: './download.component.html',
  styleUrl: './download.component.scss'
})
export class DownloadComponent {
  readonly repoUrl = 'https://github.com/Null-Pointers-Albarregas/EventvsMerida';
  readonly apkUrl = 'https://github.com/Null-Pointers-Albarregas/EventvsMerida/releases/download/Alpha/eventvs-merida.apk';
}
